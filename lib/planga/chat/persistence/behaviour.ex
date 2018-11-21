defmodule Planga.Chat.Persistence.Behaviour do
  @moduledoc """
  Behaviour to be implemented by any data-storage layer.

  We put a behaviour in-between so we can easily switch what persistence layer is actually used.
  (Mnesia, Riak, Sqlite)
  """


  @callback fetch_user_by_remote_id!(app_id :: String.t, remote_user_id :: String.t, user_name :: String.t) :: %Planga.Chat.User{} | no_return()
  @callback fetch_messages_by_conversation_id(conversation_id :: integer, sent_before_datetime ::DateTime.t) :: [%Planga.Chat.Message{}] | no_return()
  @callback fetch_conversation_by_remote_id!(app_id :: String.t, remote_id :: String.t) :: %Planga.Chat.Conversation{} | no_return()

  @callback create_message(app_id :: String.t, remote_conversation_id :: String.t, user_id :: integer,  message :: String.t, other_user_ids :: [integer]) :: %Planga.Chat.Message{}

  @callback update_username(user_id :: integer, remote_user_name :: String.t) :: :ok

  @doc """
  Hides message by setting `deleted_at`
  """
  @callback hide_message(message_id :: any) :: :ok | {:error, any}

  @doc """
  Bans chatter in app.

  `duration` is time in minutes.

  Should only be called by persons that have correct rights.
  """
  @callback ban_chatter(convesation_id :: integer, user_id :: integer, duration :: integer) :: :ok | {:error, any}

  @doc """
  Looks at current role a certain user has.

  Should only be called by persons that have correct rights.
  """
  @callback fetch_role(conversation_id :: integer, user_id :: any) :: {:ok, role :: String.t} | {:error, any}

  @doc """
  Updates the current role a certain user has.

  Should only be called by persons that have correct rights.
  """
  @callback set_role(conversation_id :: integer, user_id :: any, role :: String.t) :: :ok | {:error, any}
end
