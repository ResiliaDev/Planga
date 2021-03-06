defmodule Planga.Connection do
  @moduledoc """
  Functions to handle the initial connection someone makes to the Planga Chat Server.
  (Regardless of transport layer)
  """
  def connect(encoded_public_api_id, encoded_encrypted_conversation_info) do
    # {public_api_id, encrypted_conversation_info} =
    public_api_id = Base.decode64!(encoded_public_api_id)
    encrypted_conversation_info = Base.decode64!(encoded_encrypted_conversation_info)
    #   Planga.Connection.decode_conversation_info(encoded_qualified_conversation_info)

    api_key_pair = Planga.Connection.Persistence.fetch_api_key_pair_by_public_id!(public_api_id)

    with {:ok, secret_info} =
           Planga.Connection.decrypt_config(encrypted_conversation_info, api_key_pair) do
      remote_conversation_id = secret_info.conversation_id
      current_user_id = secret_info.current_user_id
      app_id = api_key_pair.app_id
      user = Planga.Connection.Persistence.fetch_user_by_remote_id!(app_id, current_user_id)
      Planga.Connection.subscribe_to_conversation(app_id, remote_conversation_id)

      Planga.Connection.Persistence.update_username(user.id, secret_info.current_user_name)

      Planga.Connection.maybe_update_user_role(
        app_id,
        current_user_id,
        remote_conversation_id,
        secret_info.current_user_role
      )

      socket_assigns =
        Planga.Connection.socket_info(user: user, api_key_pair: api_key_pair, config: secret_info)

      {:ok, %{secret_info: secret_info, socket_assigns: socket_assigns}}
    end
  end

  @doc """
  Updates the given conversation_user's role iff it was passed as option in the config.
  If "" was passed, role is reset to empty.

  If "moderator" was passed, user becomes a moderator.

  If it was not set (or `nil` (`null` in JSON) was passed, no changes
  are made to the current value.
  """
  def maybe_update_user_role(app_id, remote_user_id, remote_conversation_id, role) do
    if role != nil do
      Planga.Event.dispatch(
        [:apps, app_id, :conversations, remote_conversation_id, :users, remote_user_id],
        :set_role,
        %{role: role}
      )
    end
  end

  @doc """
  Transforms a string like "foobar#bazqux",
  where `foobar` is the base64-encoded public API id
  and `bazqux` is the base64-encoded encrypted conversation info

  into a tuple containing these two pieces of information, without decoding.


  TODO doctests
  """
  def decode_conversation_info(qualified_conversation_info) do
    [api_pub_id, encrypted_conversation_info] =
      qualified_conversation_info
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)

    {api_pub_id, encrypted_conversation_info}
  end

  @doc """
  Decryps a configuration that has been encrypted using the JOSE-JWK format,
  to a hash with string keys.
  """
  def decrypt_config(encrypted_config, api_key_pair) do
    Planga.Connection.Config.decrypt(encrypted_config, api_key_pair)
  end

  def socket_info(user: user, api_key_pair: api_key_pair, config: config) do
    # The reason the conversation_id is not in here,
    # is because it might not be created yet, as it is created lazily, once the first user sends a message in it.
    [
      user_id: user.id,
      api_key_pair: api_key_pair,
      app_id: api_key_pair.app_id,
      # remote_conversation_id: remote_conversation_id,
      # other_users: other_users
      config: config
    ]
  end

  def subscribe_to_conversation(app_id, remote_conversation_id) do
    PlangaWeb.Endpoint.subscribe(static_topic(app_id, remote_conversation_id))
  end

  def broadcast_new_message!(app_id, remote_conversation_id, message) do
    PlangaWeb.Endpoint.broadcast!(
      static_topic(app_id, remote_conversation_id),
      "new_remote_message",
      message
    )
  end

  def broadcast_changed_message!(app_id, remote_conversation_id, changed_message) do
    PlangaWeb.Endpoint.broadcast!(
      static_topic(app_id, remote_conversation_id),
      "changed_message",
      changed_message
    )
  end

  def broadcast_changed_conversation_user!(
        app_id,
        remote_conversation_id,
        changed_conversation_user
      ) do
    PlangaWeb.Endpoint.broadcast!(
      static_topic(app_id, remote_conversation_id),
      "changed_conversation_user",
      changed_conversation_user
    )
  end

  defp static_topic(app_id, remote_conversation_id) do
    "chat:#{app_id}:#{remote_conversation_id}"
  end

  defdelegate public_info(secret_info), to: Planga.Connection.Config
end
