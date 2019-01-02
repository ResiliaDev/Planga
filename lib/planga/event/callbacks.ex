defmodule Planga.Event.Callbacks do
  @moduledoc """
  Callbacks to be run after an event has been handled.
  The callback-functions itself are run synchroniously, but they might dispatch other, async events/messages/tasks..
  """

  @doc """
  Whenever a structure that people might be viewing live changes,
  we broadcast these changes so that they immediately see the changes in their view.
  """
  def broadcast_changes(event) do
    require Logger

    case {event.topic, event.name} do
      {[:apps, app_id, :conversations, remote_conversation_id, :messages], :new_message} ->
        Planga.Connection.broadcast_new_message!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      {[:apps, app_id, :conversations, remote_conversation_id, :messages, _message_id], _} ->
        Planga.Connection.broadcast_changed_message!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      {[:apps, app_id, :conversations, remote_conversation_id, :users, _remote_user_id], _} ->
        Planga.Connection.broadcast_changed_conversation_user!(
          app_id,
          remote_conversation_id,
          event.changed_subject
        )

      _ ->
        Logger.info("Did not broadcast anything for event #{inspect(event)}")
    end

    {:ok, event}
  end
end
