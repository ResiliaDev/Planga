defmodule PlangeWeb.ChatChannel do
  use PlangeWeb, :channel

  def join("chat:" <> conversation_id, payload, socket) do
    IO.puts("Channel id: #{conversation_id}")
    with user = %Plange.Chat.User{} <- attempt_authorization(payload, conversation_id) do
      socket =
        socket
        |> assign(:user_id, user.id)
        |> assign(:conversation_id, conversation_id)
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


  def send_previous_messages(socket) do
     messages = Plange.Chat.get_messages_by_conversation_id(socket.assigns.conversation_id)
     json_hash =
       messages
       |> Enum.map(&message_dict/1)
       |> IO.inspect(tag: "messages")
     push socket, "messages_so_far", %{messages: json_hash}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("new_message", payload, socket) do
    conversation = Plange.Chat.get_conversation_by_remote_id!(socket.assigns.conversation_id)
    user_id = socket.assigns.user_id
    message = Plange.Chat.create_good_message(conversation.id, user_id, payload["message"])

    broadcast! socket, "new_message", message_dict(message)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp attempt_authorization(payload = %{"app_id" => app_id,
                              "remote_user_id" => remote_user_id,
                              "remote_user_id_hmac" => remote_user_id_hmac,
                              "conversation_id_hmac" => conversation_id_hmac,
                             }, conversation_id) do
    IO.inspect({:payload, payload})
    with true <- Plange.Chat.check_user_hmac(app_id, remote_user_id, remote_user_id_hmac),
         true <- Plange.Chat.check_conversation_hmac(app_id, conversation_id, conversation_id_hmac) do
      Plange.Chat.get_user_by_remote_id!(payload["app_id"], payload["remote_user_id"])
    else _ -> nil
    end
  end
  defp attempt_authorization(_payload), do: false

  defp message_dict(message) do
    %{"name" => message.sender.name, "content" => message.content, "sent_at" => message.inserted_at}
  end
end
