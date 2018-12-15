defmodule Planga.Chat.Moderation.Persistence.Mnesia do
  use Exceptional, only: :named_functions

  @moduledoc """
  Uses Mnesia (using the EctoMnesia-wrapper) to persist chats and messages.
  """

  @behaviour Planga.Chat.Moderation.Persistence.Behaviour

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser}


  # def hide_message(conversation_id, message_uuid) do
  #   update_message(conversation_id, message_uuid, &Planga.Chat.Message.hide_message/1)
  # end

  def update_message(conversation_id, message_uuid, update_function) do
    # safe(fn ->
    #   Repo.transaction(fn ->
    #     Message
    #     |> Repo.get_by!(conversation_id: conversation_id, uuid: message_uuid)
    #     |> update_function.()
    #     |> Repo.update!()
    #     |> put_sender()
    #     |> put_conversation_user()
    #   end)
    # end).()
    # |> to_tagged_status
    Repo.transaction(fn ->
      with {:ok, message}     <- Repo.fetch_by(Message, conversation_id: conversation_id, uuid: message_uuid),
           new_message        <- update_function.(message),
           {:ok, result}      <- Repo.update(new_message) do
        result
        |> put_sender()
        |> put_conversation_user()
      else
        {:error, failure} -> Repo.rollback(failure)
      end
    end)
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

  # def set_role(conversation_id, user_id, role) do
  #   update_conversation_user(conversation_id, user_id, &Planga.Chat.ConversationUser.set_role(&1, role))
  # end


  # def ban_chatter(conversation_id, user_id, duration_minutes) do
  #   update_conversation_user(conversation_id, user_id, &Planga.Chat.ConversationUser.ban(&1, duration_minutes))
  # end

  def update_conversation_user(conversation_id, user_id, update_function) do
    # safe(fn ->
    #   Repo.transaction(fn ->
    #     Planga.Chat.ConversationUser
    #     |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
    #     |> update_function.()
    #     |> Repo.update!()
    #   end)
    # end).()
    # |> to_tagged_status
    Repo.transaction(fn ->
      with {:ok, conversation_user} <- Repo.fetch_by(ConversationUser, conversation_id: conversation_id, user_id: user_id),
           new_conversation_user    <- update_function.(conversation_user),
           {:ok, result}            <- Repo.update(new_conversation_user) do
        result
      else
        {:error, failure} -> Repo.rollback(failure)
      end
    end)
  end
end
