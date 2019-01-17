defmodule Planga.Crypto.JOSE do
  @moduledoc """
  Handles common decryption jobs,
  where we expect:
  - a well-formed JSON request
  - encrypted with a JOSE.JWK oct-encoded key
  """

  def decrypt(encrypted_request, secret_key) do
    with {:ok, {json_str, _jwk_decryption_details}} =
           do_jose_decrypt(encrypted_request, secret_key),
         {:ok, json_hash} <- Poison.decode(json_str) do
      {:ok, json_hash}
    else
      {:error, :invalid, _} ->
        {:error, "Could not parse JSON in encrypted request."}

      {:error, error} ->
        {:error, "Error during request decryption: #{to_string(error)}"}
    end
  end

  defp do_jose_decrypt(encrypted_data, encoded_secret_key) do
    with {:ok, secret_key} <- do_jose_decode_secret_key(encoded_secret_key) do
      try do
        res = JOSE.JWE.block_decrypt(secret_key, encrypted_data)
        {:ok, res}
      rescue
        FunctionClauseError ->
          {:error,
           "Cannot decrypt encrypted_data. Either the provided public key does not match the used secret key, or the ciphertext is malformed."}
      end
    end
  end

  defp do_jose_decode_secret_key(encoded_secret_key) do
    try do
      secret_key = JOSE.JWK.from_map(%{"k" => encoded_secret_key, "kty" => "oct"})
      {:ok, secret_key}
    rescue
      FunctionClauseError -> {:error, "invalid secret API key format!"}
    end
  end
end
