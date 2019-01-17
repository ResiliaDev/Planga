defmodule Planga.SettingsApi do
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

        {:ok, result} ->
          {:ok, %{"data" => "success"}}
      end
    end
  end

  def handle_request(conn, action, _, _) do
    {:error, :not_found, "Unknown API action."}
  end
end
