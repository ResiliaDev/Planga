defmodule PlangaWeb.ApiController do
  use PlangaWeb, :controller

  def dispatch(conn, %{"public_api_id" => public_api_id, "encrypted_request" => encrypted_request}) do
    with {:ok, api_key_pair} =
           Planga.Connection.Persistence.fetch_api_key_pair_by_public_id(public_api_id),
         {:ok, %{"action" => action, "params" => params}} =
           Planga.Crypto.JOSE.decrypt(encrypted_request, api_key_pair.secret_key) do
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
    case Planga.SettingsApi.handle_request(action, params, api_key_pair) do
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
end
