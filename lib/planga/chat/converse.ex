defmodule Planga.Chat.Converse do

  def try_create_message(message,
    %{app_id: app_id,
      user_id: user_id,
      config: %Planga.Connection.Config{conversation_id: remote_conversation_id, other_users: other_users}
    }) do
    require Logger

    if Planga.Chat.Message.valid_message?(message) do

      conversation = Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)
      {:ok, conversation_user_info} = Planga.Chat.Converse.Persistence.fetch_conversation_user_info(conversation.id, user_id)
      Logger.info(inspect(conversation_user_info))
      if conversation_user_info.banned_until && DateTime.compare(DateTime.utc_now, conversation_user_info.banned_until) == :lt do
        Logger.debug("Received message from banned user.")
        {:error, "Banned until #{conversation_user_info.banned_until}"}
      else
        other_user_ids = other_users |> Enum.map(&(&1.id))
        message = Planga.Chat.Converse.Persistence.create_message(app_id, remote_conversation_id, user_id, message, other_user_ids)

        Planga.Connection.broadcast_new_message!(app_id, remote_conversation_id, message)

        :ok
      end
    end
  end

  @doc """
  Called whenever chatter requires more (i.e. earlier) messages.
  """
  def previous_messages(%{app_id: app_id, config: %Planga.Connection.Config{conversation_id: remote_conversation_id}}, sent_before_datetime \\ nil) do

    conversation = Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)

    conversation.id
    |> Planga.Chat.Converse.Persistence.fetch_messages_by_conversation_id(sent_before_datetime)
    |> Enum.map(&Planga.Chat.Message.Presentation.message_dict/1)
  end

  def fetch_conversation_user_info(%{app_id: app_id, user_id: user_id, config: %Planga.Connection.Config{conversation_id: remote_conversation_id}}) do
    # TODO Ensure conversation is not made as soon as user connects, but only after first message was sent
    conversation = Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)
    {:ok, conversation_user_info} = Planga.Chat.Converse.Persistence.fetch_conversation_user_info(conversation.id, user_id)

    conversation_user_info
    |> Planga.Chat.ConversationUser.Presentation.conversation_user_dict()
  end
end
