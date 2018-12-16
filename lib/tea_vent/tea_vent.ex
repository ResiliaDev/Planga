defmodule TeaVent do

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
    defstruct [:topic, :name, :data, :meta, :subject, :changed_subject, :changes]
  end

  defmodule Errors do
    defmodule MissingRequiredOption do
      defexception [:message]

      @impl true
      def exception(value) do
        msg = "The options require #{inspect value} to be specified (as part of the options parameter or in the Application.env), but it was not."
        %__MODULE__{message: msg}
      end
    end

    defmodule UnrecognizedOptions do
      defexception [:message]

      @impl true
      def exception(keys) do
        msg = "The keys `#{inspect keys}` are not part of the options and could not be recognized. Did you make a syntax-error somewhere?"
        %__MODULE__{message: msg}
      end
    end
  end

  defmodule Defaults do
    def context_provider(_event, reducer) do
      reducer.({:ok, nil})
    end
  end

  @doc """

  ## Options

  - `subject_finder:` A function that, given an event, returns either `{:ok, subject}` or `{:error, some_problem}`.
  # - `reducer:` A function that, given an a subject and an event, returns either `{:ok, changed_subject}` or `{:error, some_problem}`.
  - `subject_putter:` A function that receives the event, the original subject, the changed subject and a list of changes, potentially persists the subject and/or the event. Should return either `:ok` or `{:error, some_problem}`
  - `sync_callbacks:` A list of functions that take the event as input and return `{:ok, changed_event}` or `{:error, some_error}` as output. These are called _synchronious_, and when the first one fails, the rest of the chain will not be called.
  """
  def dispatch(event = %__MODULE__.Event{}, options) do
    options = parse_options(options)

    reducer = options[:reducer]
    middleware = options[:middleware]
    # subject_finder = options[:subject_finder]
    # subject_putter = options[:subject_putter]
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
          {:error, error, subject}
        end
      end)
      # with {:ok, subject} <- subject_finder.(event),
      #      {:ok, changed_subject} <- reducer.(subject, event),
      #      changes = calc_diff(subject, changed_subject),
      #        %__MODULE__.Event{event | meta: %{subject: subject, changed_subject: changed_subject, changes: changes}}
      #      :ok <- subject_putter.(changed_subject, subject, event, changes)
    end
  end

  defp calc_diff(a = %struct_a{}, b = %struct_b{}) when struct_a == struct_b do
    a_set = a |> Map.from_struct |> MapSet.new
    b_set = b |> Map.from_struct |> MapSet.new

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
