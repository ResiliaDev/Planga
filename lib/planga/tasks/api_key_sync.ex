defmodule Planga.Tasks.ApiKeySync do
  def sync_all do
   IO.inspect("Fetching latest API keys!")
   json =
     HTTPoison.post!("http://0.0.0.0:3000/api_key_sync", "")
     |> Map.get(:body)
     |> decrypt
   IO.inspect(json)
  end

  defp decrypt(text) do
    secret_key = JOSE.JWK.from_map(%{"k" => "4eHjPZYTw7Wex455xsM5KQ", "kty" => "oct"})
    JOSE.JWE.block_decrypt(secret_key, text)
    |> elem(0)
    |> Poison.decode!()

  end

end
