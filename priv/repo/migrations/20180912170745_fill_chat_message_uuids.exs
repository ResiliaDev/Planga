defmodule Planga.Repo.Migrations.FillChatMessageUuids do
  use Ecto.Migration

  def up do
    fill_uuids()
  end

  def down do
    :ok
  end

  defp fill_uuids do
    Planga.Repo.transaction(fn ->
      EctoMnesia.Table.Stream.new(:message)
      |> Enum.each(fn message_tuple ->
        message = Planga.Repo.get!(Planga.Chat.Message, elem(message_tuple, 1))

        message
        |> Planga.Chat.Message.changeset
        |> Planga.Repo.update
      end)
    end)
  end
end
