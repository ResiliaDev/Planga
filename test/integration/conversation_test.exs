defmodule Planga.Integration.ConversationTest do
  @moduledoc """
  This module expects the testing environment to be set up such that

  `/example` points to a page where one user, who is a moderator, is part of a conversation.
  `/example2` points to a page where another user (who is not a moderator) is part of the same conversation.
  """

  use ExUnit.Case
  @moduletag :integration

  use Hound.Helpers
  use ExUnitProperties

  #   setup_all do
  #     Planga.ReleaseTasks.migrate

  #     {:ok, _} = Planga.Repo.transaction(fn ->
  #       Planga.Repo.insert!(%Planga.Chat.App{
  #             name: "Planga Test",
  #             api_key_pairs: [
  #               %Planga.Chat.APIKeyPair{public_id: "foobar", secret_key: "iv3lCL2TgVG3skeVF4l5-Q", enabled: true}
  #             ]
  # })
  #     end)
  #     :ok
  #   end

  defp fill_field_slow(element, text, timeout \\ 50) do
    click(element)

    text
    |> String.graphemes()
    |> Enum.each(fn grapheme ->
      send_text(grapheme)
      :timer.sleep(timeout)
    end)

    :timer.sleep(timeout * 10)
  end

  hound_session()

  test "Example page does not raise an error on visitation" do
    navigate_to("/example")

    assert current_path() == "/example"

    element = find_element(:class, "planga--new-message-field")
    assert element_displayed?(element)
  end

  property "Sending a message in the chat as normal user is allowed, and result visible." do
    check all text <- string(:alphanumeric, min_length: 1, max_length: 50),
              max_run_time: 5_000,
              max_runs: 3,
              max_shrinking_steps: 5 do
      navigate_to("/example")

      element = find_element(:class, "planga--new-message-field")
      # text = "The quick brown fox jumps over the lazy dog!"
      fill_field_slow(element, text)
      submit_element(element)
      :timer.sleep(500)

      assert String.contains?(visible_page_text(), text)
    end
  end

  property "Other user connected at same time sees message you send to channel" do
    check all text <- string(:alphanumeric, min_length: 1, max_length: 50),
              max_run_time: 5_000,
              max_runs: 3,
              max_shrinking_steps: 5 do
      navigate_to("/example")

      in_browser_session(:other, fn ->
        navigate_to("/example2")
      end)

      element = find_element(:class, "planga--new-message-field")
      # text = "The quick brown fox jumps over the lazy dog!"
      fill_field_slow(element, text)
      submit_element(element)
      :timer.sleep(500)

      in_browser_session(:other, fn ->
        assert String.contains?(visible_page_text(), text)
      end)
    end
  end

  property "Other user connecting later sees message you send to channel" do
    check all text <- string(:alphanumeric, min_length: 1, max_length: 50),
              max_run_time: 5_000,
              max_runs: 3,
              max_shrinking_steps: 5 do
      navigate_to("/example")

      element = find_element(:class, "planga--new-message-field")
      # text = "The quick brown fox jumps over the lazy dog!"
      fill_field_slow(element, text)
      submit_element(element)
      :timer.sleep(500)

      in_browser_session(:other, fn ->
        navigate_to("/example2")
        assert String.contains?(visible_page_text(), text)
      end)
    end
  end
end
