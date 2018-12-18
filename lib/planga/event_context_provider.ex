defmodule Planga.EventContextProvider do
  alias Planga.Repo
  alias TeaVent.Event

  def run(event = %TeaVent.Event{topic: topic}, reducer) do
    # with {:ok, subject} <- hydrate(event),
    #      {:ok, updated_event} <- reducer.(subject) do
    # end
    {status, ecto_multi} =
      with {:ok, subject} <- hydrate(event) |> IO.inspect,
           {:ok, updated_event} <- reducer.(subject) |> IO.inspect do
        changes =
          case updated_event do
            %Event{changes: nil, changed_subject: new_thing} ->
              Ecto.Changeset.change(new_thing)

            %Event{changes: changes, subject: original_thing} ->
              Ecto.Changeset.change(original_thing, changes)
          end

        ecto_multi =
          Ecto.Multi.new()
          |> Ecto.Multi.insert_or_update(:insert_or_update_subject, changes)

        {:ok, ecto_multi}
      else
        {:error, problem} -> {:error, Ecto.Multi.error(:error, problem)}
      end

    new_meta = Map.put(event.meta, :ecto_multi, ecto_multi)

    {status, %TeaVent.Event{event | meta: new_meta}}
  end

  def hydrate(event = %TeaVent.Event{topic: [:app, app_id]}) do
    Repo.fetch(Planga.Chat.App, app_id)
  end

  def hydrate(
        event = %TeaVent.Event{topic: [:app, app_id, :conversation, remote_conversation_id]}
      ) do
    {:ok,
     Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(
       app_id,
       remote_conversation_id
     )}
  end

  def hydrate(
        event = %TeaVent.Event{
          topic: [:app, app_id, :conversation, remote_conversation_id, :messages]
        }
      ) do
    {:ok, nil}
  end

  def hydrate(
        event = %TeaVent.Event{
          topic: [:app, app_id, :conversation, remote_conversation_id, :messages, message_uuid]
        }
      ) do
    # TODO more lazy conversation creation?
    conversation =
      Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(
        app_id,
        remote_conversation_id
      )

    Repo.fetch_by(Planga.Chat.Message, conversation_id: conversation.id, uuid: message_uuid)
  end
end
