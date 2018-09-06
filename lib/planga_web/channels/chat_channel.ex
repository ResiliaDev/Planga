defmodule PlangaWeb.ChatChannel do
  use PlangaWeb, :channel
  @moduledoc """
  The ChatChannel is responsible for the WebSocket (or fallback)-connection between the client
  and a single chat-conversation.
  """

  @doc """
  Implementation of Channel behaviour: Called when front-end attempts to join this conversation.
  """
  def join("encrypted_chat:" <> qualified_conversation_info, payload, socket) do
    {public_api_id, encrypted_conversation_info} = decode_conversation_info(qualified_conversation_info)
    api_key_pair = Planga.Chat.get_api_key_pair_by_public_id!(public_api_id)
    secret_info = jose_decrypt(encrypted_conversation_info, api_key_pair)
    with %{
          "conversation_id" => conversation_id,
          "current_user_id" => current_user_id
     }  = secret_info do
      app_id = api_key_pair.app_id
      user = Planga.Chat.get_user_by_remote_id!(app_id, current_user_id)
      PlangaWeb.Endpoint.subscribe("chat:#{app_id}#{conversation_id}")
      other_users = (secret_info["other_users"] || []) |> parse_other_users()
      socket = fill_socket(socket, user, api_key_pair, app_id, conversation_id, other_users)

      if secret_info["current_user_name"] do
        Planga.Chat.update_username(user.id, secret_info["current_user_name"])
      end

      send(self(), :after_join)

      {:ok, %{"current_user_name" => secret_info["current_user_name"]}, socket}

    else
      _ ->
        # TODO Improve error messages in case of missing encrypted fields!
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_, _, socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  defp jose_decrypt(encrypted_conversation_info, api_key_pair) do
    {:ok, res} = do_jose_decrypt(encrypted_conversation_info, api_key_pair)

    res
    |> elem(0)
    |> IO.inspect "The decrypted strigifiedJSON Planga will deserialize: "
    |> Poison.decode!()
  end

  defp do_jose_decrypt(encrypted_conversation_info, api_key_pair) do
    with {:ok, secret_key} <- do_jose_decode_api_key(api_key_pair) do
      try do
        res = JOSE.JWE.block_decrypt(secret_key, encrypted_conversation_info)
        {:ok, res}
      rescue
        FunctionClauseError -> {:error, "Cannot decrypt `encrypted_conversation_info`. Either the provided public key does not match the used secret key, or the ciphertext is malformed."}
      end
    end
  end

  defp do_jose_decode_api_key(api_key_pair) do
    try do
      secret_key = JOSE.JWK.from_map(%{"k" => api_key_pair.secret_key, "kty" => "oct"})
      {:ok, secret_key}
    rescue
      FunctionClauseError -> {:error, "invalid secret API key format!"}
    end
  end

  def parse_other_users(other_users) do
    other_users
    |> Enum.map(fn
      user ->
      if Map.has_key?(user, "id") do
        user_map = %{id: user["id"], name: user["name"]}
        {:ok, user_map}
      else
        {:error, "invalid `other_users` element: missing `id` field."}
      end
    end)
    |> Enum.map(&elem(&1, 1))
  end

  def public_secrets(secret_info) do
    %{
      current_user_name: secret_info["current_user_name"]
    }
  end


  defp decode_conversation_info(qualified_conversation_info) do
    [api_pub_id, encrypted_conversation_info] =
      qualified_conversation_info
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)

    {api_pub_id, encrypted_conversation_info}
  end

  defp fill_socket(socket, user, api_key_pair, app_id, remote_conversation_id, other_users) do
    socket =
      socket
      |> assign(:user_id, user.id)
      |> assign(:api_key_pair, api_key_pair)
      |> assign(:app_id, app_id)
      |> assign(:remote_conversation_id, remote_conversation_id)
      |> assign(:other_users, other_users)
  end

  @doc """
  Called immediately after joining to send latest messages to just-connected chatter.
  """
  def handle_info(:after_join, socket) do
    send_previous_messages(socket)
    {:noreply, socket}
  end

  @doc """
  Called whenever chatter requires more (i.e. earlier) messages.
  """
  def send_previous_messages(socket, sent_before_datetime \\ nil) do

    app_id = socket.assigns.app_id
    remote_conversation_id = socket.assigns.remote_conversation_id
    messages =
      app_id
      |> Planga.Chat.get_messages_by_remote_conversation_id(remote_conversation_id, sent_before_datetime)
      |> Enum.map(&message_dict/1)
    push socket, "messages_so_far", %{messages: messages}
  end


  @doc """
  Called whenever the chatter attempts to send a new message.
  """
  def handle_in("new_message", payload, socket) do
    message = payload["message"]

    if Planga.Chat.Message.valid_message?(message) do
      app_id = socket.assigns.app_id
      remote_conversation_id = socket.assigns.remote_conversation_id
      user_id = socket.assigns.user_id
      other_users = socket.assigns.other_users
      message = Planga.Chat.create_message(app_id, remote_conversation_id, user_id, message, other_users |> Enum.map(&(&1.id)))
      broadcast! socket, "new_message", message_dict(message)
    end

    {:noreply, socket}
  end


  @doc """
  Called whenever the chatter attempts to see earlier messages.
  """
  def handle_in("load_old_messages", %{"sent_before" => sent_before}, socket) do
    case NaiveDateTime.from_iso8601(sent_before) do
      {:ok, sent_before_datetime} ->
        send_previous_messages(socket, sent_before_datetime)
      _ ->
        nil
    end
    {:noreply, socket}
  end

  # Turns returned message information in a format the front-end understands.
  defp message_dict(message) do
    %{
      "name" => message.sender.name,
      "content" => message.content,
      "sent_at" => message.inserted_at
    }
  end
end
