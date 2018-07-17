defmodule Planga.Chat do
  @moduledoc """
  The Chat context.

  Handles calls related to creating and looking up chat-messages.
  """
  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser, Topic, ConversationTopic, APIKeyPair}

  @doc """
  Given a user's `remote_id`, returns the User struct.
  Will throw an Ecto.NoResultsError error if user could not be found.
  """
  def get_user_by_remote_id!(app_id, remote_user_id, user_name \\ nil) do
    {:ok, user} = Repo.transaction(fn ->
      app = Repo.get!(App, app_id)
      user =  Repo.get_by(User, [app_id: app.id, remote_id: remote_user_id])
      if user do
        user
      else
        user = Repo.insert!(%User{app_id: app.id, remote_id: remote_user_id, name: user_name})
      end
    end)
    user
  end

  defp get_messages_by_conversation_id(conversation_id, sent_before_datetime \\ nil) do
    if(sent_before_datetime) do
      from(m in Message, where: m.conversation_id == ^conversation_id and m.inserted_at < ^sent_before_datetime, order_by: [desc: :id], limit: 20)
    else
      from(Message, where: [conversation_id: ^conversation_id], order_by: [desc: :id], limit: 20)
    end
    |> Repo.all()
    |> Enum.map(&put_sender/1)
  end

  @doc """
  Returns the latest 20 messages that are part of a conversation indicated by `app_id` + `remote_conversation_id`.

  Optionally, the argument `sent_before_datetime` can be used to look back further in history.
  """
  def get_messages_by_remote_conversation_id(app_id, remote_conversation_id, sent_before_datetime \\ nil) do
    app = Repo.get!(App, app_id)
    case Repo.get_by(Conversation, app_id: app.id, remote_id: remote_conversation_id) do
      conversation = %Conversation{} ->
        get_messages_by_conversation_id(conversation.id, sent_before_datetime)
      nil ->
        []
    end
  end

  # Temporary function until EctoMnesia supports `Ecto.Query.preload` statements.
  defp put_sender(message) do
    sender = Repo.get(User, message.sender_id)
    %Message{message | sender: sender}
  end

  @doc """
  Given the conversation's `remote_id` as well as the `app_id` it is part of,
  returns the `%Planga.Conversation{}` it represents.
  """
  def get_conversation_by_remote_id!(app_id, remote_id) do
    {:ok, {app, conversation}} = Repo.transaction(fn ->
      app = Repo.get!(App, app_id)
      conversation = Repo.get_by(Conversation, app_id: app.id, remote_id: remote_id)
      if conversation do
        {app, conversation}
      else
        conversation = Repo.insert!(%Conversation{app_id: app.id, remote_id: remote_id})
        {app, conversation}
      end
    end)
    if(conversation.id != nil) do
      conversation
    else
      Repo.get_by!(Conversation, app_id: app.id, remote_id: remote_id)
    end
  end

  @doc """
  Creates a Message struct and stores it in the application,
  that will be part the conversation indicated by `app_id` and `remote_conversation_id`
  and sent by the user indicated by `user_id`.

  The to-be-sent message will be `message`.

  """
  def create_message(app_id, remote_conversation_id, user_id, message, other_user_ids) do
    {:ok, message} = Repo.transaction( fn ->
      conversation = get_conversation_by_remote_id!(app_id, remote_conversation_id)
      idempotently_add_user_to_conversation(conversation.id, user_id)

      other_user_ids
      |> Enum.map(&idempotently_add_user_with_remote_id_to_conversation(app_id, conversation.id, &1))

      Repo.insert!(
        %Message{
          id: Snowflakex.new!(),
          content: message,
          conversation_id: conversation.id,
          sender_id: user_id
        })
        |> Repo.preload(:sender)
    end)

    message
  end

  @doc """
  Adds a user to a conversation.

  Calling this function multiple times has no (extra) effect.
  """
  def idempotently_add_user_to_conversation(conversation_id, user_id) do
    {:ok, _user} = Repo.transaction(fn ->
      user = Repo.get_by(ConversationUser, conversation_id: conversation_id, user_id: user_id)
      if user do
        user
      else
        Repo.insert!(%ConversationUser{conversation_id: conversation_id, user_id: user_id})
      end
    end)
  end

  def idempotently_add_user_with_remote_id_to_conversation(app_id, conversation_id, remote_user_id) do
    user = get_user_by_remote_id!(app_id, remote_user_id)
    idempotently_add_user_to_conversation(conversation_id, user.id)
  end

  def update_username(user_id, remote_user_name) do
    Repo.transaction(fn ->
      Repo.get!(User, user_id)
      |> Ecto.Changeset.change(name: remote_user_name)
      |> Repo.update()
    end)
  end

  def get_api_key_pair_by_public_id!(pub_api_id) do
    Planga.Repo.get_by!(Planga.Chat.APIKeyPair, public_id: pub_api_id, enabled: true)
  end

end
