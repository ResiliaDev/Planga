defmodule PlangaWeb.ChatChannel do
  use PlangaWeb, :channel

  def join("chat:" <> qualified_conversation_id, payload, socket) do
    [app_id, remote_conversation_id] =
      qualified_conversation_id
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)
    with {user = %Planga.Chat.User{}, conversation_id} <- attempt_authorization(payload, app_id, remote_conversation_id) do
      socket =
        socket
        |> assign(:user_id, user.id)
        |> assign(:app_id, app_id)
        |> assign(:remote_conversation_id, remote_conversation_id)
        |> assign(:conversation_id, conversation_id)

      if payload["remote_user_name_hmac"] do
        Planga.Chat.update_user_name_if_hmac_correct(app_id, user.id, payload["remote_user_name_hmac"], payload["remote_user_name"])
      end

      Planga.Chat.idempotently_add_user_to_conversation(conversation_id, user.id)

      send(self(), :after_join)
      {:ok, socket}
    else
      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_, _, socket) do
    {:error, %{reason: "Improper channel format"}}
  end

  def handle_info(:after_join, socket) do
    send_previous_messages(socket)
    {:noreply, socket}
  end


  def send_previous_messages(socket, sent_before_datetime \\ nil) do
    conversation_id = socket.assigns.conversation_id
    messages = Planga.Chat.get_messages_by_conversation_id(conversation_id, sent_before_datetime)
    json_hash =
      messages
      |> Enum.map(&message_dict/1)
    push socket, "messages_so_far", %{messages: json_hash}
  end

  def handle_in("new_message", payload, socket) do
    # conversation = Planga.Chat.get_conversation_by_remote_id!(socket.assigns.app_id, socket.assigns.remote_conversation_id)
    conversation_id = socket.assigns.conversation_id
    user_id = socket.assigns.user_id
    message = Planga.Chat.create_good_message(conversation_id, user_id, payload["message"])

    broadcast! socket, "new_message", message_dict(message)
    {:noreply, socket}
  end

  def handle_in("load_old_messages", %{"sent_before" => sent_before}, socket) do
    case NaiveDateTime.from_iso8601(sent_before) do
      {:ok, sent_before_datetime} ->
        send_previous_messages(socket, sent_before_datetime)
      _ ->
        nil
    end
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp attempt_authorization(payload = %{
                              "remote_user_id" => remote_user_id,
                              "remote_user_id_hmac" => remote_user_id_hmac,
                              "conversation_id_hmac" => conversation_id_hmac,
                              "remote_user_name" => remote_user_name,
                             }, app_id, remote_conversation_id) do
    with true <- Planga.Chat.check_user_hmac(app_id, remote_user_id, remote_user_id_hmac),
         true <- Planga.Chat.check_conversation_hmac(app_id, remote_conversation_id, conversation_id_hmac) do

      user = Planga.Chat.get_user_by_remote_id!(app_id, remote_user_id, remote_user_name)
      conversation = Planga.Chat.get_conversation_by_remote_id!(app_id, remote_conversation_id)
      {user, conversation.id}
    else _ -> nil
    end
  end

  defp attempt_authorization(_payload, _, _), do: false

  defp message_dict(message) do
    %{
      "name" => message.sender.name,
      "content" => message.content,
      "sent_at" => message.inserted_at
    }
  end
end
