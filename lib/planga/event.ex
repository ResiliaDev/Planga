defmodule Planga.Event do
  @moduledoc """
  All incoming potential-changes to the application enter it here as event.

  This is based on the `TeaVent` library (see that library's documentation for more information).
  """
  alias TeaVent.Event

  def dispatch(topic, name, data \\ %{}, remote_user_id \\ nil, meta \\ %{}, options \\ []) do
    dispatch_event(TeaVent.Event.new(topic, name, data, meta), remote_user_id, options)
  end

  def dispatch_event(event, remote_user_id \\ nil, options \\ []) do
    options =
      options ++
        [
          context_provider: &Planga.Event.ContextProvider.run/2,
          reducer: &Planga.Event.Reducer.reducer/2,
          middleware: [
            &Planga.Event.Middleware.event_logger/1,
            &Planga.Event.Middleware.fill_time/1,
            &Planga.Event.Middleware.repo_transaction/1
          ]
        ]

    meta = Map.put(event.meta, :remote_user_id, remote_user_id)

    event = %Event{event | meta: meta}

    with {:ok, event} <- TeaVent.dispatch_event(event, options) do
      # Not a TeaVent `sync_callback` because we want to run it _after_ the middleware.
      Planga.Event.Callbacks.broadcast_changes(event)
    end
  end
end
