defmodule TeaVent do
  @moduledoc """

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
  @options_keys [:middleware, :sync_callbacks, :context_provider, :reducer]

  @options_defaults %{middleware: [],
              sync_callbacks: [],
              context_provider: &__MODULE__.Defaults.context_provider/2
              # context_provider: fn _, reducer -> reducer.({:ok, nil}) end
              # subject_finder: fn _ -> nil end,
              # subject_putter: fn _, _, _ -> :ok end
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
    """
    defstruct [:topic, :name, :data, :meta, :subject, :changed_subject, :changes]
  end

  defmodule Errors.MissingRequiredOption do
    @moduledoc """
    Raised when a required option is missing (not specified as part of the options parameter nor in the current Application.env)
    """
    defexception [:message]

    @impl true
    def exception(value) do
      msg = "The options require #{inspect value} to be specified (as part of the options parameter or in the Application.env), but it was not."
      %__MODULE__{message: msg}
    end
  end

  defmodule Errors.UnrecognizedOptions do
    @moduledoc """
    Raised when an option that was not recognized was passed to TeaVent (to catch for instance syntax errors in the option names.)
    """
    defexception [:message]

    @impl true
    def exception(keys) do
      msg = "The keys `#{inspect keys}` are not part of the options and could not be recognized. Did you make a syntax-error somewhere?"
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
  Dispatches the given `event` to the current TeaVent-based event-sourcing system.

  By default, this does very little, but it can be configured to do a lot for you!

  ## Required Options
  - `reducer:` A function that, given an a subject and an event, returns either `{:ok, changed_subject}` or `{:error, some_problem}`.

  ## Optional Options

  - `context_provider:` A function that receives the event and a reducer-function as input, and should fetch the context of the event and later update it back. See more information in the module documentation.
  - `sync_callbacks:` A list of functions that take the event as input and return `{:ok, changed_event}` or `{:error, some_error}` as output. These are called _synchronious_, and when the first one fails, the rest of the chain will not be called. See more info in the module documentation.
  - `middleware`: A list of functions that do something useful around the whole event-handling stack. See more info in the module documentation.

  """
  def dispatch(event = %__MODULE__.Event{}, options) do
    options = parse_options(options)

    reducer = options[:reducer]
    middleware = options[:middleware]
    context_provider = options[:context_provider]
    sync_callbacks = options[:sync_callbacks]

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

  defp calc_diff(a, b), do: nil

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


  defp parse_options(options) do
    options_map = Enum.into(options, %{})
    options_map_keys = options_map |> Map.keys |> MapSet.new
    allowed_keys = @options_keys |> MapSet.new
    unrecognized_keys = MapSet.difference(options_map_keys, allowed_keys)
    case unrecognized_keys |> MapSet.to_list do
      [] -> :ok
      keys -> raise __MODULE__.Errors.UnrecognizedOptions, keys
    end
    # TODO
    @options_keys
    |> Enum.map(fn key ->
      with :error <- Map.fetch(options_map, key),
           :error <- Application.fetch_env(__MODULE__, key),
           :error <- Map.fetch(@options_defaults, key) do
        raise __MODULE__.Errors.MissingRequiredOption, key
      else
        {:ok, val} -> {key, val}
      end
    end)
  end
end
