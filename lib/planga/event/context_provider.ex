defmodule Planga.Event.ContextProvider do
  alias TeaVent.Event

  def run(event = %TeaVent.Event{topic: topic}, reducer) do
    {db_preparation, subject_fun} =
      Planga.Event.ContextProvider.Hydration.hydrate(topic, event.meta)

    ecto_multi =
      Ecto.Multi.new()
      |> Ecto.Multi.merge(fn _ -> Planga.Event.ContextProvider.Hydration.fetch_creator(event) end)
      |> Ecto.Multi.append(db_preparation)
      |> Ecto.Multi.run(:subject, &fill_subject(subject_fun, &1))
      |> Ecto.Multi.run(:reducer_result, &run_reducer(event, reducer, &1))
      |> Ecto.Multi.merge(&persist_reducer_result/1)

    event = put_in(event.meta[:ecto_multi], ecto_multi)
    {:ok, event}
  end

  defp fill_subject(subject_fun, multi_info) do
    # This pattern-match is here to make debugging of the subject function easier.
    # Without this check, error messages would complain at a much later `Ecto.Multi.merge`-step.
    case subject_fun.(multi_info) do
      {:ok, res} -> {:ok, res}
      {:error, failure} -> {:error, failure}
    end
  end

  defp run_reducer(event, reducer, %{subject: subject, creator: creator}) do
    meta = Map.put(event.meta, :creator, creator)
    event = %Event{event | meta: meta}

    IO.inspect(subject, label: :reducer)
    IO.inspect(event, label: :event_before_calling_reducer)

    case reducer.(subject, event) |> IO.inspect(label: :reducer_result) do
      {:ok, res} -> {:ok, res}
      {:error, failure} -> {:error, failure}
    end
  end

  defp persist_reducer_result(%{reducer_result: event_result}) do
    changes =
      case event_result do
        %Event{changes: nil, changed_subject: new_thing} ->
          Ecto.Changeset.change(new_thing)

        %Event{changes: changes, subject: original_thing} ->
          Ecto.Changeset.change(original_thing, changes)
      end

    Ecto.Multi.new()
    |> Ecto.Multi.insert_or_update(:changed_subject, changes)
  end
end
