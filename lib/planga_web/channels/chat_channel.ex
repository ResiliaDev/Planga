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
  Called whenever chatter requires more (i.e. earlier) messages.
  """
  def send_previous_messages(socket, sent_before_datetime \\ nil) do

    remote_conversation_id = socket.assigns.config.conversation_id
    app_id = socket.assigns.app_id
    conversation = Planga.Chat.fetch_conversation_by_remote_id!(app_id, remote_conversation_id)
    messages =
      conversation.id
      |> Planga.Chat.fetch_messages_by_conversation_id(sent_before_datetime) # TODO Long line; rename function?
      |> Enum.map(&Planga.Chat.Message.Presentation.message_dict/1)
    push socket, "messages_so_far", %{messages: messages}
  end


  @doc """
  Called whenever the chatter attempts to send a new message.

  NOTE Send something else (async?) when invalid message/rate-limited etc?
  """
  def handle_in("new_message", payload, socket) do
    message = payload["message"]


    if Planga.Chat.Message.valid_message?(message) do
      %{app_id: app_id,
        user_id: user_id,
        config: %Planga.Connection.Config{conversation_id: remote_conversation_id, other_users: other_users}
      } = socket.assigns

      conversation = Planga.Chat.fetch_conversation_by_remote_id!(app_id, remote_conversation_id)
      {:ok, conversation_user_info} = Planga.Chat.Persistence.Mnesia.fetch_conversation_user_info(conversation.id, user_id)
      if conversation_user_info.banned_until && DateTime.compare(DateTime.utc_now, conversation_user_info.banned_until) == :lt do
        {:reply, %{"status" => "error", "data" => "Banned until #{conversation_user_info.banned_until}"}}
      else
        other_user_ids = other_users |> Enum.map(&(&1.id))
        message = Planga.Chat.create_message(app_id, remote_conversation_id, user_id, message, other_user_ids)

        Planga.Connection.broadcast_new_message!(app_id, remote_conversation_id, message)
      end
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

  @doc """
  Called immediately after joining to send latest messages to just-connected chatter.

  This is a separate call, to keep the `join` as lightweight as possible,
  since it is executed during startup of the Channel GenServer
  (and runs synchroniously with the Browser that is waiting for a connection).
  """
  def handle_info(:after_join, socket) do
    send_previous_messages(socket)
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "new_remote_message", payload: payload}, socket) do
    broadcast! socket, "new_remote_message", Planga.Chat.Message.Presentation.message_dict(payload)

    {:noreply, socket}
  end
end
