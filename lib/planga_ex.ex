defmodule PlangaPhoenix do
  @moduledoc """
  Easy usage of Planga inside Elixir+Phoenix applications.
  """


  require Phoenix.HTML.Tag
  require Vex

  def chat(options) do
    {:ok, options} = validate_options(options)

    encrypted_info = encrypted_conversation_info(options.private_api_key, options.conversation_id, options.current_user_id, options.current_user_name)

    Phoenix.HTML.Tag.content_tag :script,
      Phoenix.HTML.raw """
      window.onload = function(){
        new Planga(document.getElementById("#{Phoenix.HTML.escape_javascript(options.container_id)}"),
        {
          public_api_id: "#{Phoenix.HTML.escape_javascript(options.public_api_id)}",
          encrypted_options: "#{Phoenix.HTML.escape_javascript(encrypted_info)}",
          socket_location: "/socket",
        });
      };
      """
  end

  defp encrypted_conversation_info(private_api_key, conversation_id, current_user_id, current_user_name) do
    decoded_privkey = JOSE.JWK.from_map(%{"k" => private_api_key, "kty" => "oct"})
    inspect decoded_privkey
    priv_data =
      %{
        conversation_id: conversation_id,
        current_user_id: current_user_id,
        current_user_name: current_user_name
      } |> Poison.encode!

    decoded_privkey
    |> JOSE.JWE.block_encrypt(priv_data, %{"alg" => "A128GCMKW", "enc" => "A128GCM"})
    |> JOSE.JWE.compact
    |> elem(1)
  end

  defp validate_options(options) do
    errors = Vex.errors(options, [
          public_api_id: [presence: true, format: ~r/[a-zA-Z]+/],
          private_api_key: [presence: true, format: ~r/[a-zA-Z]+/],
          conversation_id: [presence: true],
          current_user_id: [presence: true],
          current_user_name: [presence: true],
          container_id: [presence: true]
        ])

    if(errors != []) do
      {:error, errors}
    else
      {:ok, options}
    end
  end
end
