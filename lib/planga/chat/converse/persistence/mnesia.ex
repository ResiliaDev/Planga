defmodule Planga.Chat.Converse.Persistence.Mnesia do
  use Exceptional, only: :named_functions

  @moduledoc """
  Uses Mnesia (using the EctoMnesia-wrapper) to persist chats and messages.
  """

  @behaviour Planga.Chat.Converse.Persistence.Behaviour

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, ConversationUser}

  def fetch_messages_by_conversation_id(conversation_id, sent_before_datetime) do
    query =
      if sent_before_datetime do
        from(
          m in Message,
          where: m.conversation_id == ^conversation_id and m.inserted_at < ^sent_before_datetime,
          order_by: [desc: :id],
          limit: 20
        )
      else
        from(
          Message,
          where: [conversation_id: ^conversation_id],
          order_by: [desc: :id],
          limit: 20
        )
      end

    query
    |> Repo.all()
    |> Enum.map(&put_sender/1)
    |> Enum.map(&put_conversation_user/1)
  end

  # Temporary function until EctoMnesia supports `Ecto.Query.preload` statements.
  defp put_sender(message) do
    sender = Repo.get(User, message.sender_id)
    %Message{message | sender: sender}
  end

  defp put_conversation_user(message) do
    if message.conversation_user_id == nil do
      conversation_user = fetch_conversation_user_info(message.conversation_id, message.user_id)
      message
      |> Ecto.Changeset.change(conversation_user_id: conversation_user.id)
      Repo.update!
    else
      conversation_user = Repo.get(ConversationUser, message.conversation_user_id)
      %Message{message | conversation_user: conversation_user}
    end
  end

  @doc """
  Given the conversation's `remote_id` as well as the `app_id` it is part of,
  returns the `%Planga.Conversation{}` it represents.
  """
  def find_or_create_conversation_by_remote_id!(app_id, remote_id) do
    {:ok, conversation} =
      Repo.transaction(fn ->
        case Repo.get_by(Conversation, app_id: app_id, remote_id: remote_id) do
          nil ->
            Repo.insert!(%Conversation{app_id: app_id, remote_id: remote_id})

          conversation ->
            conversation
        end
      end)

    conversation
  end

  def find_conversation_by_remote_id(app_id, remote_id) do
    {:ok, res} =
      Repo.transaction(fn ->
        conversation = Repo.get_by(Conversation, app_id: app_id, remote_id: remote_id)
        conversation
      end)

    case res do
      nil -> {:error, :not_found}
      conversation -> {:ok, conversation}
    end
  end

  @doc """
  Creates a Message struct and stores it in the application,
  that will be part the conversation indicated by `app_id` and `remote_conversation_id`
  and sent by the user indicated by `user_id`.

  The to-be-sent message will be `message`.

  """
  def create_message(app_id, remote_conversation_id, user_id, message_content, other_user_ids) do
    {:ok, message} =
      Repo.transaction(fn ->
        conversation = find_or_create_conversation_by_remote_id!(app_id, remote_conversation_id)
        {:ok, conversation_user} = ensure_user_partakes_in_conversation(conversation.id, user_id)

        other_user_ids
        |> Enum.map(&fetch_user_by_remote_id!(app_id, &1))
        |> Enum.each(&ensure_user_partakes_in_conversation(conversation.id, &1))

        do_create_message(message_content, conversation.id, user_id, conversation_user.id)
      end)

    message
  end

  defp do_create_message(message, conversation_id, sender_id, conversation_user_id) do
    # %Message{
    #   id: Snowflakex.new!(),
    #   content: message,
    #   conversation_id: conversation_id,
    #   sender_id: sender_id,
    #   conversation_user_id: conversation_user_id
    # }
    # |> Message.changeset
    Message.new(
      content: message,
      conversation_id: conversation_id,
      sender_id: sender_id,
      conversation_user_id: conversation_user_id
    )
    |> Repo.insert!()
    |> Repo.preload(:sender)
    |> Repo.preload(:conversation_user)
  end

  # @doc """
  # Adds a user to a conversation.
  #
  # Calling this function multiple times has no (extra) effect.
  # """
  defp ensure_user_partakes_in_conversation(conversation_id, user_id) do
    safe(fn ->
      Repo.transaction(fn ->
        user = Repo.get_by(ConversationUser, conversation_id: conversation_id, user_id: user_id)

        if user do
          user
        else
          Repo.insert!(%ConversationUser{conversation_id: conversation_id, user_id: user_id})
        end
      end)
    end).()
    |> to_tagged_status
  end

  # Given a user's `remote_id`, returns the User struct.
  # Will throw an Ecto.NoResultsError error if user could not be found.
  defp fetch_user_by_remote_id!(app_id, remote_user_id, user_name \\ nil) do
    {:ok, user} =
      Repo.transaction(fn ->
        app = Repo.get!(App, app_id)
        user = Repo.get_by(User, app_id: app.id, remote_id: remote_user_id)

        if user do
          user
        else
          Repo.insert!(%User{app_id: app.id, remote_id: remote_user_id, name: user_name})
        end
      end)

    user
  end

  def fetch_conversation_user_info(conversation_id, user_id) do
    ensure_user_partakes_in_conversation(conversation_id, user_id)
    # safe(fn ->
    #   Repo.transaction(fn ->
    #     Planga.Chat.ConversationUser
    #     |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
    #   end)
    # end).()
    # |> to_tagged_status
  end
end
