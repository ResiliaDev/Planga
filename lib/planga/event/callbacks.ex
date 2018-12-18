defmodule Planga.Event.Callbacks do
  def broadcast_changes(event) do
    case {event.topic, event.name} do
      {[:apps, app_id, :conversations, remote_conversation_id, :messages], :new_message} ->
        IO.inspect(event, label: "broadcast_changes")

        Planga.Connection.broadcast_new_message!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      {[:apps, app_id, :conversations, remote_conversation_id, :messages, message_id], _} ->
        Planga.Connection.broadcast_changed_message!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      {[:apps, app_id, :conversations, remote_conversation_id, :users, remote_user_id], _} ->
        Planga.Connection.broadcast_changed_conversation_user!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      _ ->
        IO.puts("Did not broadcast anything for event #{inspect(event)}")
    end

    {:ok, event}
  end
end
