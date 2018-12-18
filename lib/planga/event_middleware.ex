defmodule Planga.EventMiddleware do
  alias TeaVent.Event
  alias Planga.Repo

  def repo_transaction(next_stage) do
    fn event ->
      with {:ok, event = %Event{meta: meta = %{ecto_multi: ecto_multi}}} <- next_stage.(event),
           {:ok, ecto_multi_result } <- Repo.transaction(ecto_multi) do
        updated_meta = Map.put(meta, :ecto_multi, ecto_multi_result)
        updated_event =  ecto_multi_result.reducer_result
        updated_event = %Event{updated_event | meta: updated_meta, changed_subject: ecto_multi_result.changed_subject}
        {:ok, updated_event}
      end
    end
  end
end
