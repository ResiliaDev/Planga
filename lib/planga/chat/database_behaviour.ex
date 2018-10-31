defmodule Planga.Chat.DatabaseBehaviour do
  @moduledoc """
  Behaviour to be implemented by any database layer.

  We put a behaviour in-between so we can easily switch what persistence layer is actually used.
  (Mnesia, Riak, Sqlite)
  """


  @callback fetch_user_by_remote_id!(app_id :: String.t, remote_user_id :: String.t, user_name :: String.t) :: %Planga.Chat.User{} | no_return()
  @callback fetch_messages_by_conversation_id(conversation_id :: integer, sent_before_datetime ::DateTime.t) :: [%Planga.Chat.Message{}] | no_return()
  @callback fetch_conversation_by_remote_id!(app_id :: String.t, remote_id :: String.t) :: %Planga.Chat.Conversation{} | no_return()

  @callback create_message!(app_id :: String.t, remote_conversation_id :: String.t, message :: String.t, other_user_ids :: [integer]) :: %Planga.Chat.Message{} | no_return()

  @callback update_username!(user_id :: integer) :: :ok | no_return()

end
