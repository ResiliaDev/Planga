defmodule Planga.Tasks.ApiKeySync do
  require Logger
  def sync_all do
    Logger.info("Fetching latest API keys!")
    planga_dashboard_url = Application.get_env(:planga, :planga_dashboard_url)
    json =
      (planga_dashboard_url <> "/api_key_sync")
      |> HTTPoison.get!()
      |> Map.get(:body)
      |> decrypt
      |> Enum.each(&update_rails_user/1)
    Logger.info("Finished fetching API keys!")
  end

  defp decrypt(text) do
    secret_key = JOSE.JWK.from_map(%{"k" => Application.get_env(:planga, :planga_api_key_sync_password), "kty" => "oct"})

    secret_key
    |> JOSE.JWE.block_decrypt(text)
    |> elem(0)
    |> Poison.decode!()
  end

  @doc """
  Currently, the Rails system works with 'users', so this is how we are managing individual applications,
  using the user ID as app name.
  """
  def update_rails_user(user_json) do
    Planga.Repo.transaction(fn ->
      user_json["api_credentials"]
      |> Enum.each(&update_credential/1)
    end)
  end

  def update_credential(api_key_json) do
    Planga.Repo.transaction(fn ->

      app =
        case Planga.Repo.get_by(Planga.Chat.App, name: to_string(api_key_json["public_id"])) do
          nil ->
            Logger.info("Creating new app #{api_key_json["public_id"]}")
            %Planga.Chat.App{name: api_key_json["public_id"]}
          existing ->
            Logger.info("Updating existing app #{api_key_json["public_id"]}")
            existing
        end

      app =
        app
        |> Planga.Chat.App.from_json(api_key_json)
        |> Planga.Repo.insert_or_update!


      api_key_pair =
        case Planga.Repo.get(Planga.Chat.APIKeyPair, api_key_json["public_id"]) do
          nil ->
            Logger.info("Creating new key #{api_key_json["public_id"]}")
            %Planga.Chat.APIKeyPair{public_id: api_key_json["public_id"]}
          existing ->
            Logger.info("Updating existing key #{api_key_json["public_id"]}")
            existing
      end

      api_key_json =
        Map.merge(api_key_json, %{"app_id" => app.id})

      api_key_pair
      |> Planga.Chat.APIKeyPair.from_json(api_key_json)
      |> Planga.Repo.insert_or_update!
      Logger.info("Done with key #{api_key_json["public_id"]}!")
    end)
  end
end
