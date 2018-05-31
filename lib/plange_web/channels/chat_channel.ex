defmodule PlangeWeb.ChatChannel do
  use PlangeWeb, :channel

  def join("chat:" <> qualified_conversation_id, payload, socket) do
    [app_id, remote_conversation_id] =
      qualified_conversation_id
      |> String.split("#")
      |> Enum.map(&Base.decode64!/1)
    IO.inspect({"Joined Channel", qualified_conversation_id, app_id, remote_conversation_id})
    with user = %Plange.Chat.User{} <- attempt_authorization(payload, app_id, remote_conversation_id) do
      socket =
        socket
        |> assign(:user_id, user.id)
        |> assign(:app_id, app_id)
        |> assign(:remote_conversation_id, remote_conversation_id)
        |> IO.inspect

      send(self(), :after_join)
      {:ok, socket}
    else
      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    send_previous_messages(socket)
    {:noreply, socket}
  end


  def send_previous_messages(socket, sent_before_datetime \\ nil) do
    conversation = Plange.Chat.get_conversation_by_remote_id!(socket.assigns.app_id, socket.assigns.remote_conversation_id)
    IO.inspect({"CONVERSATION:", conversation})
    messages = Plange.Chat.get_messages_by_conversation_id(conversation.id, sent_before_datetime)
    json_hash =
      messages
      |> Enum.map(&message_dict/1)
      |> IO.inspect(tag: "messages")
    push socket, "messages_so_far", %{messages: json_hash}
  end

  def handle_in("new_message", payload, socket) do
    conversation = Plange.Chat.get_conversation_by_remote_id!(socket.assigns.app_id, socket.assigns.remote_conversation_id)
    user_id = socket.assigns.user_id
    message = Plange.Chat.create_good_message(conversation.id, user_id, payload["message"])

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
                             }, app_id, conversation_id) do
    IO.inspect({:payload, payload})
    with true <- Plange.Chat.check_user_hmac(app_id, remote_user_id, remote_user_id_hmac),
         true <- Plange.Chat.check_conversation_hmac(app_id, conversation_id, conversation_id_hmac) do
      Plange.Chat.get_user_by_remote_id!(app_id, remote_user_id)
    else _ -> nil
    end
  end
  defp attempt_authorization(_payload, _, _), do: false

  defp message_dict(message) do
    %{"name" => message.sender.name, "content" => message.content, "sent_at" => message.inserted_at}
  end
end
