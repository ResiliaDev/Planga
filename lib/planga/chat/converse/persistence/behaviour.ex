defmodule Planga.Chat.Converse.Persistence.Behaviour do

  @callback fetch_messages_by_conversation_id(conversation_id :: integer, sent_before_datetime ::DateTime.t) :: [%Planga.Chat.Message{}] | no_return()

  @callback find_or_create_conversation_by_remote_id!(app_id :: String.t, remote_id :: String.t) :: %Planga.Chat.Conversation{} | no_return()

  @callback create_message(app_id :: String.t, remote_conversation_id :: String.t, user_id :: integer,  message :: String.t, other_user_ids :: [integer]) :: %Planga.Chat.Message{}

  @doc """
  Looks at current role a certain user has.
  """
  @callback fetch_conversation_user_info(conversation_id :: integer, user_id :: any) :: {:ok, role :: %Planga.Chat.ConversationUser{}} | {:error, any}
end
