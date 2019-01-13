defmodule Planga.Connection.Persistence do
  persistence_implementation = __MODULE__.Mnesia
  defdelegate fetch_user_by_remote_id!(app_id, remote_user_id), to: persistence_implementation

  defdelegate fetch_user_by_remote_id!(app_id, remote_user_id, user_name),
    to: persistence_implementation

  defdelegate update_username(user_id, remote_user_name), to: persistence_implementation
  defdelegate update_user_role(user_id, remote_conversation_id, role), to: persistence_implementation

  defdelegate fetch_api_key_pair_by_public_id!(pub_api_id), to: persistence_implementation
end
