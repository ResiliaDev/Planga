defmodule Planga.Connection do
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

  def decrypt_config(encrypted_config, api_key_pair) do
    Planga.Connection.Config.decrypt(encrypted_config, api_key_pair)
  end

  def socket_info(user: user, api_key_pair: api_key_pair, config: config) do
    remote_conversation_id = config["conversation_id"]
    other_users = Planga.Connection.Config.read_other_users(config)

    [user_id: user.id,
     api_key_pair: api_key_pair,
     app_id: api_key_pair.app_id,
     remote_conversation_id: remote_conversation_id,
     other_users: other_users
    ]
  end
end
