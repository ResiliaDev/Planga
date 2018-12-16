defmodule TeaVent do
  defmodule Event do
    defstruct [:name, :data, :meta]
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
    subject_finder = options[:subject_finder]
    subject_putter = options[:subject_putter]
    sync_callbacks = options[:sync_callbacks]

    sync_chain = fn event ->
      chain_until_failure(event,
        [
          core_function(subject_finder, reducer, subject_putter)
        ] ++ sync_callbacks)
    end
    run_middleware(event, sync_chain, middleware)
  end

  defp core_function(subject_finder, reducer, subject_putter) do
    fn event ->
      with {:ok, subject} <- subject_finder.(event),
           {:ok, changed_subject} <- reducer.(subject, event),
           changes = calc_diff(subject, changed_subject),
             %__MODULE__.Event{event | meta: %{subject: subject, changed_subject: changed_subject, changes: changes}}
           :ok <- subject_putter.(changed_subject, subject, event, changes)
    end
  end

  defp calc_diff(before = %struct_a{}, after = %struct_b{}) when struct_a == struct_b do
    before_set = before |> Map.from_struct |> MapSet.new
    after_set = after |> Map.from_struct |> MapSet.new

    after_set
    |> MapSet.difference(before_set)
    |> Enum.into(%{})
  end

  defp calc_diff(before, after), do: nil

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
      {:ok, changed_event = %__MODULE__{}} -> chain_until_failure(changed_event, callbacks)
    end
  end

  @keys [:middleware, :sync_callbacks, :subject_finder, :subject_putter]

  @defaults %{middleware: [],
              sync_callbacks: [],
              subject_finder: fn _ -> nil end,
              subject_putter: fn _, _, _ -> :ok end
  }

  defp parse_options(options) do
    options_map = Enum.into(options, %{})
    # TODO
    @keys
    |> Enum.map fn key ->
      Map.get(options, key, Application.get_env(__MODULE__, key, @defaults[key]))
    end
  end
end
