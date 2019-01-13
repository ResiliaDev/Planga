defmodule Planga.Repo.Migrations.FillConversationUsersInMessages do
  use Ecto.Migration

  def up do
    fill_conversation_users()
  end

  def down do
    :ok
  end

  defp fill_conversation_users do
    require Logger
    Planga.Repo.transaction(fn ->
      EctoMnesia.Table.Stream.new(:message)
      |> Enum.each(fn message_tuple ->
        message = Planga.Repo.get!(Planga.Chat.Message, elem(message_tuple, 1))
        user = Planga.Repo.get!(Planga.Chat.User, message.sender_id)
        conversation = Planga.Repo.get!(Planga.Chat.Conversation, message.conversation_id)
        {:ok, conversation_user} = Planga.Chat.Converse.Persistence.fetch_conversation_user_info(conversation.id, user.id)
        Logger.info("Updating message #{inspect(message)}")

        message
        |> Ecto.Changeset.change(conversation_user_id: conversation_user.id)
        |> Planga.Repo.update
      end)
    end)
  end
end
