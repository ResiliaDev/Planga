defmodule Planga.Chat.Events.ReducerTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Planga.Test.Support.Generators

  # The "test" macro is imported by ExUnit.Case
  test "always pass" do
    assert true
  end

  describe ":new_message reducer" do
  end

  property "New message creation depends on message content length" do
    reducer_call = fn content, conversation_user ->
      result =
        Planga.Event.Reducer.reducer(nil, %TeaVent.Event{
          topic: [:apps, nil, :conversations, nil, :messages],
          name: :new_message,
          meta: %{creator: conversation_user},
          data: %{message: content}
        })

      expected_result = %Planga.Chat.Message{
        sender_id: conversation_user.id,
        conversation_id: conversation_user.conversation_id,
        conversation_user_id: conversation_user.id,
        content: content
      }

      {result, expected_result}
    end

    check all content <- string(:printable, min_length: 1, max_length: 1000),
              conversation_user <- filled_conversation_user_generator do
      {result, expected} = reducer_call.(content, conversation_user)
      assert {:ok, expected} = result
    end

    check all content <- string(:printable, max_length: 0),
              conversation_user <- filled_conversation_user_generator do
      {result, _expected} = reducer_call.(content, conversation_user)
      assert {:error, [content: _]} = result
    end

    check all content <- string(:printable, min_length: 10_000),
              conversation_user <- filled_conversation_user_generator do
      {result, _expected} = reducer_call.(content, conversation_user)
      assert {:error, [content: _]} = result
    end
  end
end
