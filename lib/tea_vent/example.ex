defmodule TeaVent.Example do
  alias TeaVent.Event
  def run(event, state) do
    TeaVent.dispatch(event, reducer: &reduce/2, context_provider: injected_context_provider(state))
    receive do
      new_state -> new_state
    end
  end

  def reduce(message, %Event{topic: {:messages, 1}, name: "delete"}) do
    {:ok, %{message | deleted: true}}
  end

  def reduce(_, %Event{topic: :messages, name: "create", data: %{content: content}}) do
    {:ok, %{id: 301283938210123, deleted: false, content: content}}
  end

  def injected_context_provider(injected_state = %{messages: messages, events: events}) do
    fn
      %Event{topic: {:messages, id}}, reducer ->
        result =
          messages
          |> Map.get(id, {:error, :not_found})
          |> reducer.()
      case result do
        # {:error, error, subject} -> {:error, error, subject}
        {:ok, event = %Event{changed_subject: updated_message}} ->
          new_state = %{injected_state | messages: messages |> Map.put(id, updated_message), events: [event | events]}
          send_state_to_self(new_state)
          {:ok, event}
        error -> error
      end
      %Event{topic: :messages}, reducer ->
        case reducer.(nil) do
          {:ok, event = %Event{changed_subject: created_message}} ->
            new_state = %{injected_state | messages: messages |> Map.put(created_message.id, created_message), events: [event | events]}
            send_state_to_self(new_state)
            {:ok, event}
          error -> error
        end
    end
  end

  defp send_state_to_self(state) do
    IO.inspect(state)
    send self(), state
  end
end
