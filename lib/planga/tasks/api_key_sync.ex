defmodule Planga.Tasks.ApiKeySync do
  def sync_all do
    IO.inspect("Fetching latest API keys!")
    json =
      HTTPoison.post!("http://0.0.0.0:3000/api_key_sync", "")
      |> Map.get(:body)
      |> decrypt
      |> Enum.each(&update_credential/1)
    IO.inspect(json)
  end

  defp decrypt(text) do
    secret_key = JOSE.JWK.from_map(%{"k" => "4eHjPZYTw7Wex455xsM5KQ", "kty" => "oct"})

    secret_key
    |> JOSE.JWE.block_decrypt(text)
    |> elem(0)
    |> Poison.decode!()
  end

  def update_credential(api_key_json) do
    IO.inspect(api_key_json)
    Planga.Repo.transaction(fn ->
      api_key_pair = case Planga.Repo.get(Planga.Chat.APIKeyPair, api_key_json["public_id"]) do
        nil ->
                         IO.inspect("NEW KEY")
          %Planga.Chat.APIKeyPair{public_id: api_key_json["public_id"]}
        existing ->
                         IO.inspect("EXISTING KEY")
          existing
      end

      api_key_pair
      |> IO.inspect
      |> Planga.Chat.APIKeyPair.from_json(api_key_json)
      |> IO.inspect
      |> Planga.Repo.insert_or_update!
      |> IO.inspect
    end)
  end
end
