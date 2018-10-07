defmodule Planga.Connection.Config do
  @moduledoc """
  This module handles the decryption and parsing of the Encrypted Configuration that is sent
  when someone attempts to make a connection to the Planga Chatserver.
  """

  @doc """

  Decryps a configuration that has been encrypted using the JOSE-JWK format,
  to a hash with string keys.
  """
  def decrypt(encrypted_info, api_key_pair) do
    config = jose_decrypt(encrypted_info, api_key_pair.secret_key)
    with %{"conversation_id" => _remote_conversation_id, "current_user_id" => _current_user_id} = config do
      {:ok, config}
    else
      _ ->
        {:error, "improper configuration"}
    end
  end

  @doc """
  Returns a hash containing the information
  that, if the secret_info was correct,
  is now public information to be returned and used in the browser on connection success.

  TODO doctests
  """
  def public_info(secret_info) do
    %{"current_user_name" => secret_info["current_user_name"]}
  end

  @doc """
  Reads and parses the 'other_users' field of the secret_info.
  Falls back to the default (an empty list).

  TODO doctests
  """
  def read_other_users(encrypted_info) do
    encrypted_info["other_users"] || [] |> parse_other_users()
  end

  defp parse_other_users(other_users) do
    other_users
    |> Enum.map(fn
      user ->
      if Map.has_key?(user, "id") do
        user_map = %{id: user["id"], name: user["name"]}
        {:ok, user_map}
      else
        {:error, "invalid `other_users` element: missing `id` field."}
      end
    end)
    |> Enum.map(&elem(&1, 1))
  end


  defp jose_decrypt(encrypted_conversation_info, secret_key) do
    {:ok, res} = do_jose_decrypt(encrypted_conversation_info, secret_key)

    res
    |> elem(0)
    |> IO.inspect(label: "The decrypted strigifiedJSON Planga will deserialize: ")
    |> Poison.decode!()
  end

  defp do_jose_decrypt(encrypted_conversation_info, encoded_secret_key) do
    with {:ok, secret_key} <- do_jose_decode_api_key(encoded_secret_key) do
      try do
        res = JOSE.JWE.block_decrypt(secret_key, encrypted_conversation_info)
        {:ok, res}
      rescue
        FunctionClauseError -> {:error, "Cannot decrypt `encrypted_conversation_info`. Either the provided public key does not match the used secret key, or the ciphertext is malformed."}
      end
    end
  end

  defp do_jose_decode_api_key(encoded_secret_key) do
    try do
      secret_key = JOSE.JWK.from_map(%{"k" => encoded_secret_key, "kty" => "oct"})
      {:ok, secret_key}
    rescue
      FunctionClauseError -> {:error, "invalid secret API key format!"}
    end
  end
end
