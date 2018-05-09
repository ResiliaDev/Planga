defmodule PlangeWeb.ChatChannel do
  use PlangeWeb, :channel

  def join("chat:" <> channel_id, payload, socket) do
    IO.puts("Channel id: #{channel_id}")
    if authorized?(payload) do
      socket =
        socket
        |> assign(:channel_id, channel_id)
        |> IO.inspect
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
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
    # conversation_id = Plange.Chat.get_conversation!(channel_id: socket.assigns.channel_id)
    # IO.inspect("Creating message in #{inspect conversation_id} sent by #{inspect payload.sender}")

    
    # |> Plange.Chat.create_message(conversation_id, payload)

    broadcast! socket, "new_message", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
