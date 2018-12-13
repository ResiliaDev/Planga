defmodule Planga.Chat.Moderation.Persistence.Mnesia do
  use Exceptional, only: :named_functions

  @moduledoc """
  Uses Mnesia (using the EctoMnesia-wrapper) to persist chats and messages.
  """

  @behaviour Planga.Chat.Moderation.Persistence.Behaviour

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser}


  def set_role(conversation_id, user_id, role) do
    safe(fn ->
      Repo.transaction(fn ->
        Planga.Chat.ConversationUser
        |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
        |> Ecto.Changeset.change(role: role)
        |> Repo.update!()
      end)
    end).()
    |> to_tagged_status
  end

  def hide_message(conversation_id, message_uuid) do
    safe(fn ->
      Repo.transaction(fn ->
        Message
        |> Repo.get_by!(conversation_id: conversation_id, uuid: message_uuid)
        |> Ecto.Changeset.change(deleted_at: DateTime.utc_now)
        |> Repo.update!()
        |> put_sender()
        |> put_conversation_user()
      end)
    end).()
    |> to_tagged_status
  end

  def ban_chatter(conversation_id, user_id, duration_minutes) do
    import Ecto.Query
    now = DateTime.utc_now
    ban_end = Timex.add(now, Timex.Duration.from_minutes(duration_minutes))
    safe(fn ->
      Repo.transaction(fn ->
        Planga.Chat.ConversationUser
        bannable_conversation_users = Planga.Chat.ConversationUser #from cu in Planga.Chat.ConversationUser, where: is_nil(cu.role)

        bannable_conversation_users
        |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
        |> Ecto.Changeset.change(banned_until: ban_end)
        |> Repo.update!()
      end)
    end).()
    |> to_tagged_status
  end

  # Temporary function until EctoMnesia supports `Ecto.Query.preload` statements.
  defp put_sender(message) do
    sender = Repo.get(User, message.sender_id)
    %Message{message | sender: sender}
  end

  defp put_conversation_user(message) do
    conversation_user = Repo.get(ConversationUser, message.conversation_user_id)
    %Message{message | conversation_user: conversation_user}
  end
end
