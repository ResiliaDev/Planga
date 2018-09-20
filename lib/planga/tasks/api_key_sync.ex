defmodule Planga.Tasks.ApiKeySync do
  def sync_all do
   IO.inspect("Fetching latest API keys!")
   res =
     HTTPoison.post! "http://0.0.0.0:3000/api_key_sync", ""
     |> IO.inspect
   json = Poison.decode!(res.body)
   IO.inspect(json)
  end
end
