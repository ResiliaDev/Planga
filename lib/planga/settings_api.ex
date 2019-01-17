defmodule Planga.SettingsApi do
  @moduledoc """
  API to lookup and change settings w.r.t. users in one single Planga.Chat.App.
  """

  # Simple macro that ensures that we can match on parameters,
  # and there is an automatic normalized error-response if it does not match.
  defmacrop with_parameters(params, match, do: body) do
    quote do
      case unquote(params) do
        unquote(match) ->
          unquote(body)
        _ ->
          {:error, "Missing parameters"}
      end
    end
  end

  @doc """
  Entry-point of an API request.
  """
  def handle_request(action, params, api_key_pair) do
    case action do
      "set_role" ->
        set_role(params, api_key_pair)

      _ ->
        {:error, :not_found, "Unknown API action."}
    end
  end

  @doc """
  
  """
  def set_role(params, api_key_pair) do
    with_parameters(params, %{
      "role" => role,
      "conversation_id" => remote_conversation_id,
      "user_id" => remote_user_id
    }) do
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
end
