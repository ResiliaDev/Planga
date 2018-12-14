defmodule PlangaWeb.ChatChannel do
  use PlangaWeb, :channel
  @moduledoc """
  The ChatChannel is responsible for the WebSocket (or fallback)-connection between the client
  and a single chat-conversation.
  """

  @doc """
  Implementation of Channel behaviour: Called when front-end attempts to join this conversation.
  """
  def join("encrypted_chat:" <> qualified_conversation_info, _payload, socket) do
    with {:ok, %{secret_info: secret_info, socket_assigns: socket_assigns}}
    <- Planga.Connection.connect(qualified_conversation_info) do

      send(self(), :after_join)
      socket = fill_socket(socket, socket_assigns)

      {:ok, Planga.Connection.public_info(secret_info), socket}
    else
        # NOTE This is a prime location to log in a way visible to the App Developer.
      {:error, reason} ->
        {:error, %{reason: reason}}
      _ ->
        {:error, %{reason: "Unable to connect. Improper connection details?"}}
    end
  end

  def join(_channel_name, _payload, _socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  defp fill_socket(socket, socket_assigns) do
    socket_assigns
    |> Enum.reduce(socket, fn {key, value}, socket -> assign(socket, key, value) end)
  end


  @doc """
  Called whenever the chatter attempts to send a new message.

  NOTE Send something else (async?) when invalid message/rate-limited etc?
  """
  def handle_in("new_message", payload, socket) do
    message = payload["message"]

    case Planga.Chat.Converse.try_create_message(message, socket.assigns) do
      {:error, error_message} ->
        {:reply, {:error, %{"data" => error_message}}, socket}
      :ok ->
        {:noreply, socket}
    end
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


  def handle_in("hide_message", %{"message_uuid" => message_uuid}, socket) do
    case Planga.Chat.Moderation.hide_message(message_uuid, socket.assigns) do
      {:error, error_message} ->
        {:reply, {:error, %{"data" => error_message}}, socket}
      {:ok, updated_message} ->
        Planga.Connection.broadcast_changed_message!(socket.assigns.app_id, socket.assigns.config.conversation_id, updated_message)
        {:noreply, socket}
    end
  end

  def handle_in("ban_user", %{"user_uuid" => user_to_ban_id, "duration_minutes" => duration_minutes}, socket) do
    case Planga.Chat.Moderation.ban_user(user_to_ban_id, duration_minutes, socket.assigns) do
      {:error, error_message} ->
        {:reply, {:error, %{"data" => error_message}}, socket}
      {:ok, updated_user_conversation_info} ->
        Planga.Connection.broadcast_changed_conversation_user!(socket.assigns.app_id, socket.assigns.config.conversation_id, updated_user_conversation_info)
        {:noreply, socket}
    end
  end

  @doc """
  Called immediately after joining to send latest messages to just-connected chatter.

  This is a separate call, to keep the `join` as lightweight as possible,
  since it is executed during startup of the Channel GenServer
  (and runs synchroniously with the Browser that is waiting for a connection).

  """
  def handle_info(:after_join, socket) do
    send_connecting_conversation_user_info(socket)
    send_previous_messages(socket)
    {:noreply, socket}
  end


  # NOTE There is a lot of seeming repetition here. Maybe create presentation-protocol, and iterate over these message clauses at compile-time?
  def handle_info(%Phoenix.Socket.Broadcast{event: "new_remote_message", payload: payload}, socket) do
    broadcast! socket, "new_remote_message", Planga.Chat.Message.Presentation.message_dict(payload)

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "changed_message", payload: payload}, socket) do
    broadcast! socket, "changed_message", Planga.Chat.Message.Presentation.message_dict(payload)

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "changed_conversation_user", payload: payload}, socket) do
    if socket.assigns.user_id == payload.user_id do
      broadcast! socket, "changed_your_conversation_user_info", Planga.Chat.ConversationUser.Presentation.conversation_user_dict(payload)
    else
      broadcast! socket, "changed_conversation_user_info", Planga.Chat.ConversationUser.Presentation.conversation_user_dict(payload)
    end

    {:noreply, socket}
  end

  @doc """
  Called whenever chatter requires more (i.e. earlier) messages.
  """
  def send_previous_messages(socket, sent_before_datetime \\ nil) do
    messages = Planga.Chat.Converse.previous_messages(socket.assigns, sent_before_datetime)
    push socket, "messages_so_far", %{messages: messages}
  end

  def send_connecting_conversation_user_info(socket) do
    presentable_conversation_user_info = Planga.Chat.Converse.fetch_conversation_user_info(socket.assigns)
    broadcast! socket, "changed_your_conversation_user_info", presentable_conversation_user_info
    {:noreply, socket}
  end
end

