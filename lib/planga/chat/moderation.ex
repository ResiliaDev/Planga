defmodule Planga.Chat.Moderation do
  require Logger
  alias Planga.Chat.Moderation

  def hide_message(
        message_uuid,
        socket_assigns = %{
          app_id: app_id,
          user_id: user_id,
          config: %Planga.Connection.Config{conversation_id: remote_conversation_id}
        }
      ) do
    Logger.info(
      "Request to remove message with UUID `#{message_uuid}`; Socket assigns: #{
        inspect(socket_assigns)
      }"
    )

    conversation =
      Moderation.Persistence.find_or_create_conversation_by_remote_id!(
        app_id,
        remote_conversation_id
      )

    with :ok <- ensure_moderator!(conversation.id, user_id) do
      Moderation.Persistence.update_message(
        conversation.id,
        message_uuid,
        &Planga.Chat.Message.hide_message/1
      )
    end
  end

  def ban_user(
        user_to_ban_id,
        duration_minutes,
        socket_assigns = %{
          app_id: app_id,
          user_id: user_id,
          config: %Planga.Connection.Config{conversation_id: remote_conversation_id}
        }
      ) do
    Logger.info(
      "Request to ban user with ID #{user_to_ban_id}; Socket assigns: #{inspect(socket_assigns)}"
    )

    conversation =
      Moderation.Persistence.find_or_create_conversation_by_remote_id!(
        app_id,
        remote_conversation_id
      )

    with :ok <- ensure_moderator!(conversation.id, user_id) do
      Moderation.Persistence.update_conversation_user(
        conversation.id,
        user_to_ban_id,
        &Planga.Chat.ConversationUser.ban(&1, duration_minutes)
      )
    end
  end

  defp ensure_moderator!(conversation_id, user_id) do
    {:ok, conversation_user_info} =
      Moderation.Persistence.fetch_conversation_user_info(conversation_id, user_id)

    case conversation_user_info.role do
      "moderator" ->
        :ok

      _ ->
        {:error, "You are not allowed to perform this action"}
    end
  end

  def set_role(conversation_id, user_id, role) do
    Moderation.Persistence.update_conversation_user(
      conversation_id,
      user_id,
      &Planga.Chat.ConversationUser.set_role(&1, role)
    )
  end
end
