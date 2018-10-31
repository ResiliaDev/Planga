defmodule Planga.Chat.DatabaseBehaviour do
  @moduledoc """
  Behaviour to be implemented by any database layer.

  We put a behaviour in-between so we can easily switch what persistence layer is actually used.
  (Mnesia, Riak, Sqlite)
  """


  @callback fetch_user_by_remote_id!(app_id, remote_user_id, user_name) :: {:ok, %Planga.Chat.User{}} | {:error, any}
  @callback fetch_messages_by_conversation_id(conversation_id, sent_before_datetime) :: [%Planga.Chat.Message{}]
end
