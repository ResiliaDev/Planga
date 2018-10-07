defmodule Planga.Authentication do
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
    Planga.Authentication.Config.decrypt(encrypted_config, api_key_pair)
  end
end
