defmodule Planga.EventMiddleware do
  alias TeaVent.Event
  alias Planga.Repo

  def repo_transaction(next_stage) do
    fn event ->
      with {:ok, event = %Event{meta: meta = %{ecto_multi: ecto_multi}}} <- next_stage.(event) do
        ecto_multi_result = Repo.transaction(ecto_multi)
        updated_meta = Map.put(meta, :ecto_multi, ecto_multi_result)
        event = %Event{event | meta: updated_meta}
        {:ok, event}
      end
    end
  end
end
