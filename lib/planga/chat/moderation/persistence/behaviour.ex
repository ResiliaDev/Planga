defmodule Planga.Chat.Moderation.Persistence.Behaviour do

  @callback update_message(conversation_id :: integer, message_uuid :: String.t, update_function :: (%Planga.Chat.Message{} -> %Ecto.Changeset{data: %Planga.Chat.Message{}})) :: {:ok, updated_message :: %Planga.Chat.Message{}} | {:error, any}

  @callback update_conversation_user(conversation_id :: integer, user_id :: integer, update_function :: (%Planga.Chat.ConversationUser{} -> %Ecto.Changeset{data: %Planga.Chat.ConversationUser{}})) :: {:ok, updated_conversation_user :: %Planga.Chat.ConversationUser{}} | {:error, any}
  # @doc """
  # Hides message by setting `deleted_at`
  # """
  # @callback hide_message(conversation_id :: integer, message_uuid :: String.t) :: {:ok, updated_message :: %Planga.Chat.Message{}} | {:error, any}

  # @doc """
  # Bans chatter in app.

  # `duration` is time in minutes.

  # Should only be called by persons that have correct rights.
  # """
  # @callback ban_chatter(convesation_id :: integer, user_id :: integer, duration_minutes :: integer) :: :ok | {:error, any}

  # @doc """
  # Updates the current role a certain user has.

  # Should only be called by persons that have correct rights.
  # """
  # @callback set_role(conversation_id :: integer, user_id :: any, role :: String.t) :: :ok | {:error, any}
end
