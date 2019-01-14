defmodule Planga.Connection.Persistence.Behaviour do
  @callback fetch_user_by_remote_id!(
              app_id :: String.t(),
              remote_user_id :: String.t(),
              user_name :: String.t()
            ) :: %Planga.Chat.User{} | no_return()

  @callback update_username(user_id :: integer, remote_user_name :: String.t()) :: :ok

  @callback fetch_api_key_pair_by_public_id(pub_api_id :: String.t()) ::
              {:ok, %Planga.Chat.APIKeyPair{}} | {:error, any()}
end
