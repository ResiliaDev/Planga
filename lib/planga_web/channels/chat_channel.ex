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
    with {:ok, %{secret_info: secret_info, socket_assigns: socket_assigns}} <- Planga.Connection.connect(qualified_conversation_info) do
      socket =
        socket_assigns
        |> Enum.reduce(socket, fn {key, value}, socket -> assign(socket, key, value) end)

      send(self(), :after_join)

      {:ok, Planga.Connection.public_info(secret_info), socket}
    else
      {:error, reason} ->
        {:error, %{reason: reason}}
      _ ->
        {:error, %{reason: "Unable to connect. Improper connection details?"}}
    end
  end

  def join(_, _, socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  defp static_topic(app_id, conversation_id) do
    "chat:#{app_id}#{conversation_id}"
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
      message = Planga.Chat.create_message(app_id, remote_conversation_id, user_id, message, other_users
        |> Enum.map(&(&1.id)))

      Planga.Connection.broadcast_new_message!(app_id, remote_conversation_id, message)
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

  def handle_info(event = %Phoenix.Socket.Broadcast{event: "new_remote_message", payload: payload}, socket) do
    IO.inspect(payload)
    broadcast! socket, "new_remote_message", message_dict(payload)

    {:noreply, socket}
  end

  # Turns returned message information in a format the front-end understands.
  defp message_dict(message) do
    %{
      "uuid" => message.uuid,
      "name" => message.sender.name |> html_escape,
      "content" => message.content |> html_escape,
      "sent_at" => message.inserted_at
    }
  end

  defp html_escape(unsafe_string) do
    unsafe_string
    |> Phoenix.HTML.html_escape
    |> Phoenix.HTML.safe_to_string
  end
end
