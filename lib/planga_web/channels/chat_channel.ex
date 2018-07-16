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
    {app_id, encrypted_conversation_info} = decode_conversation_info(qualified_conversation_info)
    secret_info = jose_decrypt(encrypted_conversation_info, app_id)
    with %{
          "conversation_id" => conversation_id,
          "current_user_id" => current_user_id
     }  = secret_info do
      user = Planga.Chat.get_user_by_remote_id!(app_id, current_user_id)
      PlangaWeb.Endpoint.subscribe("chat:" <> app_id <> "#" <> conversation_id)
      socket = fill_socket(socket, user, app_id, conversation_id)

      if(secret_info["current_user_name"]) do
        Planga.Chat.update_username(user.id, secret_info["current_user_name"])
      end

      send(self(), :after_join)

      {:ok, %{"current_user_name" => secret_info["current_user_name"]},socket}

    else
      _ ->
        # TODO Improve error messages in case of missing encrypted fields!
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_, _, socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  defp jose_decrypt(encrypted_conversation_info, pub_api_id) do
    priv_api_key = lookup_private_api_key(pub_api_id)
    JOSE.JWE.block_decrypt(priv_api_key, encrypted_conversation_info)
    |> elem(0)
    |> Poison.decode!()
  end

  def public_secrets(secret_info) do
    %{
      current_user_name: secret_info["current_user_name"]
    }
  end

  defp lookup_private_api_key(pub_api_id) do
    # TODO
    JOSE.JWK.from_oct(<<0::128>>)
  end

  defp decode_conversation_info(qualified_conversation_info) do
    [app_id, encrypted_conversation_info] =
      qualified_conversation_info
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)

    {app_id, rencrypted_conversation_info}
  end

  defp fill_socket(socket, user, app_id, remote_conversation_id) do
    socket =
      socket
      |> assign(:user_id, user.id)
      |> assign(:app_id, app_id)
      |> assign(:remote_conversation_id, remote_conversation_id)
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
      Planga.Chat.get_messages_by_remote_conversation_id(app_id, remote_conversation_id, sent_before_datetime)
      |> Enum.map(&message_dict/1)
    push socket, "messages_so_far", %{messages: messages}
  end

  @doc """
  Called whenever the chatter attempts to send a new message.
  """
  def handle_in("new_message", payload, socket) do
    message = payload["message"]

    if Planga.Chat.valid_message?(message) do
      app_id = socket.assigns.app_id
      remote_conversation_id = socket.assigns.remote_conversation_id
      user_id = socket.assigns.user_id
      message = Planga.Chat.create_message(app_id, remote_conversation_id, user_id, message)
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
