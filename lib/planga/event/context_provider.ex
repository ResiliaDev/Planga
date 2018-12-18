defmodule Planga.Event.ContextProvider do
  alias TeaVent.Event

  def run(event = %TeaVent.Event{topic: topic}, reducer) do
    {db_preparation, subject_fun} =
      Planga.Event.ContextProvider.Hydration.hydrate(topic, event.meta)

    ecto_multi =
      Ecto.Multi.new()
      |> Ecto.Multi.merge(fn _ -> Planga.Event.ContextProvider.Hydration.fetch_creator(event) end)
      |> Ecto.Multi.append(db_preparation)
      |> Ecto.Multi.run(:subject, fn multi_info ->
        case subject_fun.(multi_info) do
          {:ok, res} -> {:ok, res}
          {:error, failure} -> {:error, failure}
        end
      end)
      |> Ecto.Multi.run(:reducer_result, fn %{subject: subject, creator: creator} ->
        meta = Map.put(event.meta, :creator, creator)
        event = %Event{event | meta: meta}

        IO.inspect(subject, label: :reducer)
        IO.inspect(event, label: :event_before_calling_reducer)

        case reducer.(subject, event) |> IO.inspect(label: :reducer_result) do
          {:ok, res} -> {:ok, res}
          {:error, failure} -> {:error, failure}
        end
      end)
      |> Ecto.Multi.merge(fn %{reducer_result: event_result} ->
        changes =
          case event_result do
            %Event{changes: nil, changed_subject: new_thing} ->
              Ecto.Changeset.change(new_thing)

            %Event{changes: changes, subject: original_thing} ->
              Ecto.Changeset.change(original_thing, changes)
          end

        Ecto.Multi.new()
        |> Ecto.Multi.insert_or_update(:changed_subject, changes)
      end)

    new_meta = Map.put(event.meta, :ecto_multi, ecto_multi)

    {:ok, %TeaVent.Event{event | meta: new_meta}}
  end
end
