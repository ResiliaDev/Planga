defmodule TeaVent do
  @moduledoc """
  TeaVent allows you to perform event-dispatching in a style that is a mixture of Event Sourcing and The 'Elm Architecture' (TEA).

  The idea behind this is twofold:

  1. Event dispatching is separated from event handling. The event handler (the `reducer`) can thus be a pure function, making it very easy to reason about it, and test it in isolation.
  2. How subjects of the event handling are found and how the results are stored back to your application can be completely configured. This also means that it is easier to reason about and test in isolation.

  The module strives to make it easy to work with a variety of different set-ups:

  - 'full' Event Sourcing where events are always made and persisted, and the state-changes are done asynchroniously (and potentially there are multiple state-representations (i.e. event-handlers) working on the same queue of events).
  - a 'classical' relational-database setup where this can be treated as single-source-of-truth, and events/state-changes are only persisted when they are 'valid'.
  - a TEA-style application setup, where our business-domain model representation changes in a pure way.
  - A distributed-database setup where it is impossible to view your data-model as a 'single-source-of-truth' (making database-constraints impossible to work with), but the logical contexts of most events do not overlap, which allows us to handle constraints inside the application logic that is set up in TEA-style.

  The main entrance point of events is `TeaVent.dispatch()`

  ### Context Provider function

  The configured Context Provider function receives two arguments as input: The current `event`, and a 'wrapped' reducer function.

  The purpose of the Context Provider is a bit that of a 'lens' (or more specifically: A 'prism') from functional programming: It should find the precise subject (the 'logical context') based on the `topic` of the event, and after trying to combine the subject with the event, it should store the altered subject back (if successful) or do some proper error resolution (if not successful).

  It should:
  1. Based on the `topic` in the event (and potentially other fields), find the `subject` of the event.
  2. Call the passed 'wrapped' `reducer`-function with this `subject`.
  3. pattern-match on the result of this  'wrapped' `reducer`-function:
    - `{:ok, updated_event}` -> The `updated_event` has the `subject`, `changed_subject` and `changes`-field filled in. The context provider.
    - `{:error, some_problem}` is returned whenever the event could not be applied. The ContextProvider might decide to still persist the event, or do nothing. (Or e.g. roll back the whole database-transaction, etc).

  Examples for Context Providers could be:

  - a GenServer that contains a list of internal structures, which ensures that whenever an event is dispatched, this is done inside a _call_ to the GenServer, such that it is handled synchroniously w.r.t. the GenServer's state.
  - A (relational-)database-wrapper which fetches a representation of a database-row, and updates it based on the results.

  ### Synchronious Callbacks

  These callbacks are called in-order with the result of the ContextProvider.
  Each of them should return either `{:ok, potentially_altered_event}` or `{:error, some_problem}`.
  The next one will only be called if the previous one was successful.

  #### Asynchronious Callbacks

  These can be modeled on top of Synchronious Callbacks by sending a message with the event to wherever you'd want to handle it asynchroniously. TeaVent does not contain a built-in option for this, because there are many different approaches to do this. A couple that you could easily use are:

  - Perform a `Phoenix.PubSub.broadcast!` (requires the 'phoenix_pubsub' library). This is probably the most 'Event-Source'-y of these solutions, because any place can subscribe to these events. Do note that using this will restrict you to certain kinds of `topic`-formats (i.e. 'binary-only')
  - Start a `GenStage` or `Flow`-stream with the event result. (requires the 'gen_stage'/'flow' libraries)
  - Spawn a `Task` for each of the things you'd want to do asynchroniously.
  - Cast a GenServer that does something with the result.

  ### Middleware

  A middleware-function is called with one argument: The next ('more inner') middleware-function. The return value of a middleware-function should be a function that takes an event, and calls the next middleware-function with this event. What it does _before_ and _after_ calling this function is up to the middleware (it can even decide not to call the next middleware-function, for instance).
  The function that the middleware returns should take the event as input and return it as output (potentially adding things to e.g. the `meta`-field or other fields of the event). Yes, it is possible to return non-event structures from middleware, but this will make it difficult to chain middleware, unless the more 'higher-up' middleware also takes this other structure as return result, so it is not advised to do so.

  Middleware is powerful, which means that it should be used sparingly!

  Examples of potential middleware are:

  - A wrapper that wraps the event-handling in a database-transaction. (e.g. Ecto's `Repo.transaction`)
  - A wrapper that measures the duration of the event-handling code or performs some other instrumentation on it.
  """

  # @keys [:middleware, :sync_callbacks, :subject_finder, :subject_putter]
  @configuration_keys [:middleware, :sync_callbacks, :context_provider, :reducer]

  @configuration_defaults %{middleware: [],
              sync_callbacks: [],
              context_provider: &__MODULE__.Defaults.context_provider/2
              # context_provider: fn _, reducer -> reducer.({:ok, nil}) end
              # subject_finder: fn _ -> nil end,
              # subject_putter: fn _, _, _ -> :ok end
  }

  @type reducer(data_model) :: (data_model, Event.t -> ({:ok, data_model} | {:error, any()}))
  @type reducer() :: reducer(any)

  @type context_provider() :: (Event.t, reducer() -> ({:ok, Event.t} | {:error, any()}))
  @type sync_callback :: (Event.t -> ({:ok, Event.t} | {:error, any()}))
  @type middleware_function :: (middleware_function -> (Event.t -> {:ok, Event.t} | {:error, any()}))

  @type configuration :: %{
    reducer: reducer(),
    middleware: [middleware_function],
    sync_callbacks: [sync_callback],
    context_provider: [context_provider]
  }

  defmodule Event do
    @moduledoc """
    The data-representation of the occurrence of an event that is forwarded through the TeaVent stack.

    ## Fields:

    `topic`: An identification of the 'logical context' the event works on.
    `name`: The kind of event that is happening.
    `data`: More information that determines what this event is trying to change.
    `subject`: This field is filled in by the `context_provider` (if you have one), based on the `topic`, to contain a concrete representation of the logical context the event works on.
    `changed_subject`: This field is filled in by the result of calling the `resolver` function. It is how the `subject` will look like after it has been altered by the event.
    `changes`: This is automatically filled in by `TeaVent` once `subject` and `changed_subject` are filled in (and if and only if both of them are maps or structs) to contain a map of changes between the two. This map contains all keys+values that are different in `changed_subject` from `subject`.

    It is allowed to pattern-match on these fields, but `subject`, `changed_subject` and `changes` will be filled-in automatically by TeaVent. (`topic`, `name`, `data` and `meta` are allowed to be accessed/altered directly.)
    """
    @enforce_keys [:topic, :name]
    defstruct [:topic, :name, :data, :subject, :changed_subject, :changes, meta: %{}]
    @type t :: %__MODULE__{topic: any(), name: binary() | atom(), meta: map(), subject: any(), changed_subject: any(), changes: map()}

    def new(topic, name, data \\ %{}, meta \\ %{}) do
      %__MODULE__{topic: topic, name: name, data: data, meta: meta}
    end
  end

  defmodule Errors.MissingRequiredConfiguration do
    @moduledoc """
    Raised when a required option is missing (not specified as part of the configuration parameter nor in the current Application.env)
    """
    defexception [:message]

    @impl true
    def exception(value) do
      msg = "The configuration require #{inspect value} to be specified (as part of the configuration parameter or in the Application.env), but it was not."
      %__MODULE__{message: msg}
    end
  end

  defmodule Errors.UnrecognizedConfiguration do
    @moduledoc """
    Raised when an option that was not recognized was passed to TeaVent (to catch for instance syntax errors in the option names.)
    """
    defexception [:message]

    @impl true
    def exception(keys) do
      msg = "The keys `#{inspect keys}` are not part of the configuration and could not be recognized. Did you make a syntax-error somewhere?"
      %__MODULE__{message: msg}
    end
  end

  defmodule Defaults do
    # This module contains default implementations of some of the TeaVent option functions,
    # which cannot be specified as anonymous functions because those are not serializable at compile-time.
    @moduledoc false

    def context_provider(_event, reducer) do
      reducer.({:ok, nil})
    end
  end

  @doc """
  Creates an event based on the `topic`, `name` and `data` given, and dispatches it using the given configuration.


  ## Required Configuration
  - `reducer:` A function that, given an a subject and an event, returns either `{:ok, changed_subject}` or `{:error, some_problem}`.

  ## Optional Configuration

  - `context_provider:` A function that receives the event and a reducer-function as input, and should fetch the context of the event and later update it back. See more information in the module documentation.
  - `sync_callbacks:` A list of functions that take the event as input and return `{:ok, changed_event}` or `{:error, some_error}` as output. These are called _synchronious_, and when the first one fails, the rest of the chain will not be called. See more info in the module documentation.
  - `middleware`: A list of functions that do something useful around the whole event-handling stack. See more info in the module documentation.

  """
  def dispatch(topic, name, data \\ %{}, configuration \\ []) do
    dispatch_event(__MODULE__.Event.new(topic, name, data), configuration)
  end

  @doc """
  Dispatches the given `event` (that was created before using e.g. `TeaVent.Event.new`)
  to the current TeaVent-based event-sourcing system.

  Takes the same configuration as `TeaVent.dispatch`.
  """
  def dispatch_event(event = %__MODULE__.Event{}, configuration \\ []) do
    configuration = parse_configuration(configuration)

    reducer = configuration[:reducer]
    middleware = configuration[:middleware]
    context_provider = configuration[:context_provider]
    sync_callbacks = configuration[:sync_callbacks]

    sync_chain = fn event ->
      chain_until_failure(event,
        [
          core_function(context_provider, reducer)
        ] ++ sync_callbacks)
    end
    run_middleware(event, sync_chain, middleware)
  end

  defp core_function(context_provider, reducer) do
    fn event ->
      context_provider.(event, fn subject ->
        with {:ok, changed_subject} <- reducer.(subject, event),
        changes = calc_diff(subject, changed_subject) do
          {:ok, %__MODULE__.Event{event | subject: subject, changed_subject: changed_subject, changes: changes}}
        else
          {:error, error} ->
          {:error, error}
        end
      end)
    end
  end

  defp calc_diff(a = %struct_a{}, b = %struct_b{}) when struct_a == struct_b do
    calc_diff(Map.from_struct(a), Map.from_struct(b))
  end
  defp calc_diff(a = %{}, b = %{}) do
    a_set = a |> MapSet.new
    b_set = b |> MapSet.new

    b_set
    |> MapSet.difference(a_set)
    |> Enum.into(%{})
  end

  defp calc_diff(_a, _b), do: nil

  defp run_middleware(event, sync_fun, middleware) do
    combined_middleware =
      middleware
      |> Enum.reverse()
      |> Enum.reduce(sync_fun, fn outer_fun, inner_fun -> outer_fun.(inner_fun) end)

    combined_middleware.(event)
  end

  # Chains the given list of functions until any one of them returns a failure result.
  defp chain_until_failure(event, []), do: {:ok, event}
  defp chain_until_failure(event, [callback | callbacks]) do
    case callback.(event) do
      {:error, error} -> {:error, error, event}
      {:ok, changed_event = %__MODULE__.Event{}} -> chain_until_failure(changed_event, callbacks)
    end
  end


  defp parse_configuration(configuration) do
    configuration_map = Enum.into(configuration, %{})
    configuration_map_keys = configuration_map |> Map.keys |> MapSet.new
    allowed_keys = @configuration_keys |> MapSet.new
    unrecognized_keys = MapSet.difference(configuration_map_keys, allowed_keys)
    case unrecognized_keys |> MapSet.to_list do
      [] -> :ok
      keys -> raise __MODULE__.Errors.UnrecognizedConfiguration, keys
    end
    # TODO
    @configuration_keys
    |> Enum.map(fn key ->
      with :error <- Map.fetch(configuration_map, key),
           :error <- Application.fetch_env(__MODULE__, key),
           :error <- Map.fetch(@configuration_defaults, key) do
        raise __MODULE__.Errors.MissingRequiredConfiguration, key
      else
        {:ok, val} -> {key, val}
      end
    end)
  end
end
