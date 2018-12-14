defmodule Planga.Chat.Moderation do
  require Logger

  def hide_message(message_uuid, socket_assigns = %{app_id: app_id, user_id: user_id, config: %Planga.Connection.Config{conversation_id: remote_conversation_id}}) do
    Logger.info "Request to remove message with UUID `#{message_uuid}`; Socket assigns: #{inspect(socket_assigns)}"

    conversation = Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)
    with :ok <- ensure_moderator!(conversation.id, user_id) do
      Planga.Chat.Moderation.Persistence.hide_message(conversation.id, message_uuid)
    end
  end

  def ban_user(user_to_ban_id, duration_minutes, socket_assigns = %{app_id: app_id, user_id: user_id, config: %Planga.Connection.Config{conversation_id: remote_conversation_id}}) do
    Logger.info "Request to ban user with ID #{user_to_ban_id}; Socket assigns: #{inspect(socket_assigns)}"

    conversation = Planga.Chat.fetch_conversation_by_remote_id!(app_id, remote_conversation_id)
    with :ok <- ensure_moderator!(conversation.id, user_id) do
      Planga.Chat.Moderation.Persistence.ban_chatter(conversation.id, user_to_ban_id, duration_minutes)
    end
  end

  defp ensure_moderator!(conversation_id, user_id) do
    {:ok, conversation_user_info} = Planga.Chat.Converse.Persistence.fetch_conversation_user_info(conversation_id, user_id)
    case conversation_user_info.role do
      "moderator" ->
        :ok
      _ ->
        {:error, "You are not allowed to perform this action"}
    end
  end
end
