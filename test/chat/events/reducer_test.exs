defmodule Planga.Chat.Events.ReducerTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Planga.Test.Support.Generators

  describe ":new_message reducer" do
    defp send_chat_message_event(content, creator) do
      result =
        Planga.Event.Reducer.reducer(nil, %TeaVent.Event{
          topic: [:apps, nil, :conversations, nil, :messages],
          name: :new_message,
          meta: %{creator: creator},
          data: %{message: content}
        })

      expected_result = %Planga.Chat.Message{
        sender_id: creator.user.id,
        conversation_id: creator.conversation_id,
        conversation_user_id: creator.id,
        content: content
      }

      {result, expected_result}
    end

    property "New message creation depends on message content length" do
      check all content <- string(:printable, min_length: 1, max_length: 1000),
                conversation_user <- filled_conversation_user_generator() do
        {result, expected} = send_chat_message_event(content, conversation_user)
        assert {:ok, success} = result
        assert %Planga.Chat.Message{} = success
        assert success.sender_id == expected.sender_id
        assert success.conversation_id == expected.conversation_id
        assert success.conversation_user_id == expected.conversation_user_id
        assert success.content == expected.content
      end
    end

    property "New message creation fails on empty messages" do
      check all content <- string(:printable, max_length: 0),
                conversation_user <- filled_conversation_user_generator() do
        {result, _expected} = send_chat_message_event(content, conversation_user)
        assert {:error, [content: _]} = result
      end
    end

    property "New message creation fails on too long messages" do
      check all content <- string(:printable, min_length: 10_000),
                conversation_user <- filled_conversation_user_generator() do
        {result, _expected} = send_chat_message_event(content, conversation_user)
        assert {:error, [content: _]} = result
      end
    end
  end
end
