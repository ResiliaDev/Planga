defmodule PlangaWeb.ApiController do
  use PlangaWeb, :controller

  def dispatch(conn, %{"public_api_id" => public_api_id, "encrypted_request" => encrypted_request}) do
    with {:ok, api_key_pair} =
           Planga.Connection.Persistence.fetch_api_key_pair_by_public_id(public_api_id),
         {:ok, %{"action" => action, "params" => params}} =
           jose_decrypt(encrypted_request, api_key_pair.secret_key) do
      call_decrypted(conn, action, params, api_key_pair)
    else
      {:error, _} ->
        conn
        |> put_status(401)
        |> json(%{"status" => 401, "data" => "Authorization failed"})

      _ ->
        conn
        |> put_status(400)
        |> json(%{
          "status" => 400,
          "data" => "Bad request; probably missing `action` and `params` keys."
        })
    end
  end

  def call_decrypted(conn, action, params, api_key_pair) do
    case handle_request(conn, action, params, api_key_pair) do
      {:ok, response_map} ->
        json(conn, Map.merge(%{"status" => 200}, response_map))

      {:error, status_code_or_atom, error_map} ->
        conn
        |> put_status(status_code_or_atom)
        |> json(error_map)

      {:error, error_map} ->
        conn
        |> put_status(400)
        |> json(%{"status" => 400, "data" => error_map})
    end
  end

  def handle_request(conn, action, params, api_key_pair)

  def handle_request(conn, "set_role", params, api_key_pair) do
    role = params["role"]
    remote_conversation_id = params["conversation_id"]
    remote_user_id = params["user_id"]

    if role == nil || remote_conversation_id == nil || remote_user_id == nil do
      {:error, "Missing parameters"}
    else
      case Planga.Event.dispatch(
             [
               :apps,
               api_key_pair.app_id,
               :conversations,
               remote_conversation_id,
               :users,
               remote_user_id
             ],
             :set_role,
             %{role: role}
           ) do
        {:error, error, _} ->
          {:error, 400, %{"data" => "Invalid arguments"}}
        {:ok, result} -> {:ok, %{"data" => "success"}}
      end
    end
  end

  def handle_request(conn, action, _, _) do
    {:error, :not_found, "Unknown API action."}
  end

  defp jose_decrypt(encrypted_request, secret_key) do
    with {:ok, {json_str, _jwk_decryption_details}} =
           do_jose_decrypt(encrypted_request, secret_key),
         {:ok, json_hash} <- Poison.decode(json_str) do
      {:ok, json_hash}
    else
      {:error, :invalid, _} ->
        {:error, "Could not parse JSON in encrypted configuration."}

      {:error, error} ->
        {:error, "Invalid Planga configuration: #{to_string(error)}"}
    end
  end

  defp do_jose_decrypt(encrypted_conversation_info, encoded_secret_key) do
    with {:ok, secret_key} <- do_jose_decode_api_key(encoded_secret_key) do
      try do
        res = JOSE.JWE.block_decrypt(secret_key, encrypted_conversation_info)
        {:ok, res}
      rescue
        FunctionClauseError ->
          {:error,
           "Cannot decrypt `encrypted_conversation_info`. Either the provided public key does not match the used secret key, or the ciphertext is malformed."}
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
