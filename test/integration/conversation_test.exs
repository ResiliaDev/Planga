defmodule Planga.Integration.ConversationTest do
  @moduledoc """
  This module expects the testing environment to be set up such that

  `/example` points to a page where one user, who is a moderator, is part of a conversation.
  `/example2` points to a page where another user (who is not a moderator) is part of the same conversation.
  """

  use ExUnit.Case
  use Hound.Helpers

  defp fill_field_slow(element, text, timeout \\ 10) do
    click(element)
    text
    |> String.graphemes
    |> Enum.each(fn grapheme ->
      send_text(grapheme)
      :timer.sleep(timeout)
    end)
  end

  hound_session()

  test "Example page does not raise an error on visitation" do
    navigate_to("/example")

    assert current_path() == "/example"

    element = find_element(:class, "planga--new-message-field")
    assert element_displayed?(element)
  end

  test "Sending a message in the chat as normal user is allowed, and result visible." do
    navigate_to("/example")

    element = find_element(:class, "planga--new-message-field")
    assert element_enabled?(element)
    text = "The quick brown fox jumps over the lazy dog!"
    fill_field_slow(element, text)
    submit_element(element)

    assert String.contains?(visible_page_text(), text)
  end

  test "Other user connected at same time sees message you send to channel" do
    navigate_to("/example")

    in_browser_session(:other, fn ->
      navigate_to("/example2")
    end)

    element = find_element(:class, "planga--new-message-field")
    assert element_enabled?(element)
    text = "The quick brown fox jumps over the lazy dog!"
    fill_field_slow(element, text)
    submit_element(element)

    in_browser_session(:other, fn ->
      assert String.contains?(visible_page_text(), text)
    end)
  end


  test "Other user connecting later sees message you send to channel" do
    navigate_to("/example")

    element = find_element(:class, "planga--new-message-field")
    assert element_enabled?(element)
    text = "The quick brown fox jumps over the lazy dog!"
    fill_field_slow(element, text)
    submit_element(element)

    in_browser_session(:other, fn ->
      navigate_to("/example2")
      assert String.contains?(visible_page_text(), text)
    end)
  end
end
