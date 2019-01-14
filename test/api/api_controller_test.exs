defmodule PlangaWeb.ApiControllerTest do

  use ExUnit.Case, async: true
  use ExUnitProperties
  import Phoenix.ConnTest

  import Planga.Test.Support.Generators
  @endpoint PlangaWeb.Endpoint
  @moduletag :api

  setup_all do
    Planga.Repo.transaction(fn ->
      Planga.Repo.insert!(%Planga.Chat.App{
            name: "Planga Test",
            api_key_pairs: [
              %Planga.Chat.APIKeyPair{public_id: "foobar2", secret_key: "iv3lCL2TgVG3skeVF4l5-Q", enabled: true}
            ]
})
    end)
    api_key_pair = Planga.Repo.get_by!(Planga.Chat.APIKeyPair, public_id: "foobar2")
    [api_key_pair: api_key_pair]
  end

  defp build_encrypted_request(action, params, api_key_pair) do
    decoded_privkey = JOSE.JWK.from_map(%{"k" => api_key_pair.secret_key, "kty" => "oct"})
    pubkey = api_key_pair.public_id
    priv_data =
      %{"action" => action,
        "params" => params
       }
       |> Poison.encode!()

    encrypted_request =
      decoded_privkey
      |> JOSE.JWE.block_encrypt(priv_data, %{"alg" => "A128GCMKW", "enc" => "A128GCM"})
      |> JOSE.JWE.compact()
      |> elem(1)

    %{"public_api_id" => api_key_pair.public_id, "encrypted_request" => encrypted_request}
    |> Poison.encode!()
  end

  defp build_json_conn() do
    build_conn()
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> Plug.Conn.put_req_header("content-type", "application/json")
  end

  describe "set_role" do
    test "With missing parameters" do
      conn = PlangaWeb.ApiController.call_decrypted(build_conn(), "set_role", %{}, nil)
      assert conn.status == 400
      assert conn.resp_body == Poison.encode!(%{"status" => 400, "data" => "Missing parameters"})
    end
    test "With missing parameters 2", context do
      request = build_encrypted_request("set_role", %{}, context[:api_key_pair])
      IO.inspect(request, label: :request)
      conn =
        build_json_conn()
        |> post("/api/v1", request)

      assert conn.status == 400
      assert conn.resp_body == Poison.encode!(%{"status" => 400, "data" => "Missing parameters"})
    end
  end
end
