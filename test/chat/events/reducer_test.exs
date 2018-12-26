defmodule Planga.Chat.Events.ReducerTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Planga.Test.Support.Generators

  # The "test" macro is imported by ExUnit.Case
  test "always pass" do
    assert true
  end

  property "New message creation depends on message content length" do
    check all content <- string(:printable, min_length: 1, max_length: 1000),
      conversation_user <- filled_conversation_user_generator do
      res = Planga.Event.Reducer.reducer(nil, %TeaVent.Event{topic: [:apps, nil, :conversations, nil, :messages],
                                                             name: :new_message,
                                                             meta: %{creator: conversation_user},
                                                             data: %{message: content}
                                                            })
      expected_message =
        %Planga.Chat.Message{
          sender_id: conversation_user.id,
          conversation_id: conversation_user.conversation_id,
          conversation_user_id: conversation_user.id,
          content: content,
        }
      assert {:ok, expected_message} = res
    end
  end
end
