defmodule Planga.Phoenix do
  @moduledoc """
  Easy usage of the Planga Seamless Chat Service inside an Elixir+Phoenix application.
  """

  require Phoenix.HTML.Tag
  require Vex

  @doc """
  Given the correct configuration options,
  creates a HTML snippet that can be included in your application's HTML output.
  """
  def chat(options) do
    {:ok, options} = validate_options(options)

    options =
      options
      |> Map.put_new(:other_users, [])

    encrypted_info = encrypted_config(
      options.private_api_key,
      options.conversation_id,
      options.current_user,
      options.other_users
    )

    options =
      options
      |> Map.put_new(:server_location, "chat.planga.io")
      |> Map.put_new(:container_id, "planga-chat-#{Phoenix.HTML.escape_javascript(encrypted_info)}")

    [
      Phoenix.HTML.Tag.content_tag(:script, "", src: "#{options.server_location}/js/js_snippet.js"),
      Phoenix.HTML.Tag.content_tag(:div, "", id: options.container_id),
      Phoenix.HTML.Tag.content_tag(:script,
        Phoenix.HTML.raw """
        window.onload = function(){
        new Planga(document.getElementById("#{Phoenix.HTML.escape_javascript(options.container_id)}"),
        {
        public_api_id: "#{Phoenix.HTML.escape_javascript(options.public_api_id)}",
        encrypted_options: "#{Phoenix.HTML.escape_javascript(encrypted_info)}",
        socket_location: "#{options.server_location}/socket",
        });
        };
        """)
    ]
  end

  @doc """
  Given the correct configuration options,
  creates a string representation of the encrypted options.
  This is useful only for advanced use-cases, in which you want to create the Planga HTML snippet yourself.
  """
  def encrypted_config(private_api_key, conversation_id, current_user = %{id: _, name: _}, other_users) when is_list(other_users) do
    decoded_privkey = JOSE.JWK.from_map(%{"k" => private_api_key, "kty" => "oct"})
    inspect decoded_privkey
    priv_data =
      %{
        conversation_id: conversation_id,
        current_user_id: current_user.id,
        current_user_name: current_user.name
      }
      |> Poison.encode!()

    decoded_privkey
    |> JOSE.JWE.block_encrypt(priv_data, %{"alg" => "A128GCMKW", "enc" => "A128GCM"})
    |> JOSE.JWE.compact()
    |> elem(1)
  end

  defp validate_options(options) do
    with [] <- Vex.errors(options, %{
                  :public_api_id => [presence: true, format: ~r/[a-zA-Z]+/],
                  :private_api_key => [presence: true, format: ~r/[a-zA-Z]+/],
                  :conversation_id => [presence: true],
                  :current_user => [presence: true],
                          }),
         [] <- Vex.errors(options.current_user, %{
               id: [presence: true],
               name: [presence: true]
                          })
      do
      {:ok, options}
      else
        errors ->
          {:error, errors}
    end
  end
end
