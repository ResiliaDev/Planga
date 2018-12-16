defmodule TeaVent.EctoExample do
  alias TeaVent.Event
  alias Planga.Repo

  def dispatch(event, reducer) do
    TeaVent.dispatch(event, reducer: reducer, context_provider: &context_provider/2)
  end

  def context_provider(event = %Event{topic: [schema, id]}, reducer) when is_atom(schema) and is_integer(id) do
    struct = schema |> fetch(id)
    case reducer.(struct) do
      {:ok, event = %Event{changes: changes}} ->
        struct
        |> Ecto.Changeset.change(changes)
        |> Repo.update
      error ->
        error
    end
  end

  def context_provider(event = %Event{topic: [schema | clauses]}, reducer) when is_atom(schema) do
    struct = schema |> fetch_by(clauses)
    case reducer.(struct) do
      {:ok, event = %Event{changes: changes}} ->
        struct
        |> Ecto.Changeset.change(changes)
        |> Repo.update
      error ->
        error
    end
  end


  defp fetch(queryable, id) do
    case Repo.get(queryable, id) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  defp fetch_by(queryable, keys) do
    case Repo.get_by(queryable, keys) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end
end
