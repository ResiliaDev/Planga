defmodule Planga.Chat.Moderation do
  def hide_message(message_uuid, socket_assigns = %{app_id: app_id, user_id: user_id, config: %Planga.Connection.Config{conversation_id: remote_conversation_id}}) do
    require Logger
    Logger.info "Request to remove message with UUID `#{message_uuid}`; Socket assigns: #{inspect(socket_assigns)}"

    # TODO Split off in its own function
    conversation = Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)
    {:ok, conversation_user_info} = Planga.Chat.Converse.Persistence.fetch_conversation_user_info(conversation.id, user_id)
    if conversation_user_info.role != "moderator" do
      {:error, "You are not allowed to perform this action"}
    else
      Planga.Chat.Moderation.Persistence.hide_message(conversation.id, message_uuid)
    end
  end
end
