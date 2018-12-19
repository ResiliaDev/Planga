defmodule Planga.Event.Middleware do
  @moduledoc """
  Contains middleware to be run for every incoming event.
  """
  alias TeaVent.Event
  alias Planga.Repo

  @doc """
  Wraps an incoming event inside a DB transaction, such that it's results are:

  - handled inside one atomic transaction
  - are persisted afterwards (as a whole or not at all)
  """
  def repo_transaction(next_stage) do
    fn event ->
      with {:ok, %Event{meta: meta = %{ecto_multi: ecto_multi}}} <- next_stage.(event),
           IO.inspect(ecto_multi |> Ecto.Multi.to_list()),
           {:ok, ecto_multi_result} <- Repo.transaction(ecto_multi) do
        updated_meta = Map.put(meta, :ecto_multi, ecto_multi_result)
        updated_event = ecto_multi_result.reducer_result

        updated_event = %Event{
          updated_event
          | meta: updated_meta,
            changed_subject: ecto_multi_result.changed_subject
        }

        {:ok, updated_event}
      end
    end
  end

  @doc """
  Fills the `started_at` field into incoming event's `meta` info.

  By using this field from the event, the reducer itslef can be kept pure (and inside tests we could construct events where the `started_at` field is static).

  After the event handling was finished, the `finished_at`, which is therefore only available from within the `sync_callbacks` or higher-up middleware.
  """
  def fill_time(next_stage) do
    fn event ->
      updated_meta = Map.put(event.meta, :started_at, DateTime.utc_now())
      event = %Event{event | meta: updated_meta}

      with {:ok, result_event} = next_stage.(event) do
        updated_meta = Map.put(event.meta, :finished_at, DateTime.utc_now())
        result_event = %Event{result_event | meta: updated_meta}
        {:ok, result_event}
      end
    end
  end
end
