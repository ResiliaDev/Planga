defmodule Planga.Integration.ConversationTest do
  use ExUnit.Case
  use Hound.Helpers

  hound_session()

  test "Example page does not raise an error on visitation" do
    navigate_to("/example")

    assert current_path() == "/example"

    element = find_element(:name, "planga--new-message-field")
    assert element_displayed?(element)
  end

  test "Sending a message in the chat as normal user is allowed, and result visible." do
    navigate_to("/example")

    element = find_element(:name, "planga--new-message-field")
    assert element_enabled?(element)
    text = "The quick brown fox jumps over the lazy dog!"
    fill_field(element, text)
    submit_element(element)

    assert String.contains?(visible_page_text(), text)
  end


  test "Other user connected at same time sees message you send to channel" do
    navigate_to("/example")

    in_browser_session(:other, fn ->
      navigate_to("/example")
    end)

    element = find_element(:name, "planga--new-message-field")
    assert element_enabled?(element)
    text = "The quick brown fox jumps over the lazy dog!"
    fill_field(element, text)
    submit_element(element)

    in_browser_session(:other, fn ->
      assert String.contains?(visible_page_text(), text)
    end)
  end
end
