defmodule PlangaWeb.ChatChannel do
  use PlangaWeb, :channel
  @moduledoc """
  The ChatChannel is responsible for the WebSocket (or fallback)-connection between the client
  and a single chat-conversation.
  """

  @doc """
  Implementation of Channel behaviour: Called when front-end attempts to join this conversation.
  """
  def join("chat:" <> qualified_conversation_info, payload, socket) do
    {app_id, remote_conversation_id} = decode_conversation_id(qualified_conversation_info)
    secret_info = jose_decrypt(remote_conversation_id, app_id)
    IO.inspect(secret_info)
    # with user = %Planga.Chat.User{} <- attempt_authorization(payload, app_id, remote_conversation_id) do
    #   socket = fill_socket(socket, user, app_id, remote_conversation_id)
    #   maybe_update_username(payload, app_id, user)

    #   send(self(), :after_join)
      {:ok, socket}
    # else
    #   _ ->
    #     {:error, %{reason: "unauthorized"}}
    # end
  end

  def join(_, _, socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  defp jose_decrypt(encrypted_conversation_info, pub_api_id) do
    IO.inspect(encrypted_conversation_info)
    priv_api_key = lookup_private_api_key(pub_api_id)
    IO.inspect(priv_api_key)
    JOSE.JWE.block_decrypt(priv_api_key, encrypted_conversation_info)
    |> elem(0)
    |> Poison.decode!()
  end

  defp lookup_private_api_key(pub_api_id) do
    # TODO
    JOSE.JWK.from_oct(<<0::128>>)
  end

  defp decode_conversation_id(qualified_conversation_id) do
    [app_id, remote_conversation_id] =
      qualified_conversation_id
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)

    {app_id, remote_conversation_id}
  end

  defp fill_socket(socket, user, app_id, remote_conversation_id) do
    socket =
      socket
      |> assign(:user_id, user.id)
      |> assign(:app_id, app_id)
      |> assign(:remote_conversation_id, remote_conversation_id)
  end

  defp maybe_update_username(payload, app_id, user) do
    if payload["remote_user_name_hmac"] do
      Planga.Chat.HMAC.update_user_name_if_hmac_correct(app_id, user.id, payload["remote_user_name_hmac"], payload["remote_user_name"])
    end
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

  # Authorization logic
  defp attempt_authorization(payload = %{
                              "remote_user_id" => remote_user_id,
                              "remote_user_id_hmac" => remote_user_id_hmac,
                              "conversation_id_hmac" => remote_conversation_id_hmac,
                              "remote_user_name" => remote_user_name,
                             }, app_id, remote_conversation_id) do
    with true <- Planga.Chat.HMAC.check_user(app_id, remote_user_id, remote_user_id_hmac),
         true <- Planga.Chat.HMAC.check_conversation(app_id, remote_conversation_id, remote_conversation_id_hmac) do

      user = Planga.Chat.get_user_by_remote_id!(app_id, remote_user_id, remote_user_name)
      user
    else _ -> nil
    end
  end

  defp attempt_authorization(_payload, _, _), do: false

  # Turns returned message information in a format the front-end understands.
  defp message_dict(message) do
    %{
      "name" => message.sender.name,
      "content" => message.content,
      "sent_at" => message.inserted_at
    }
  end
end
