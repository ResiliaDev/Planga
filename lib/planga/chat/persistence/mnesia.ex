defmodule Planga.Chat.Persistence.Mnesia do
  use Exceptional, only: :named_functions

  @moduledoc """
  Uses Mnesia (using the EctoMnesia-wrapper) to persist chats and messages.
  """

  @behaviour Planga.Chat.Persistence.Behaviour

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser}

  @doc """
  Given a user's `remote_id`, returns the User struct.
  Will throw an Ecto.NoResultsError error if user could not be found.
  """
  def fetch_user_by_remote_id!(app_id, remote_user_id, user_name \\ nil) do
    {:ok, user} = Repo.transaction(fn ->
      app = Repo.get!(App, app_id)
      user =  Repo.get_by(User, [app_id: app.id, remote_id: remote_user_id])
      if user do
        user
      else
        Repo.insert!(%User{app_id: app.id, remote_id: remote_user_id, name: user_name})
      end
    end)
    user
  end

  def fetch_messages_by_conversation_id(conversation_id, sent_before_datetime) do
    query = if sent_before_datetime do
      from(m in Message, where: m.conversation_id == ^conversation_id and m.inserted_at < ^sent_before_datetime, order_by: [desc: :id], limit: 20)
    else
      from(Message, where: [conversation_id: ^conversation_id], order_by: [desc: :id], limit: 20)
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
    IO.inspect(message)
    conversation_user = Repo.get(ConversationUser, message.conversation_user_id)
    %Message{message | conversation_user: conversation_user}
  end

  @doc """
  Given the conversation's `remote_id` as well as the `app_id` it is part of,
  returns the `%Planga.Conversation{}` it represents.
  """
  def fetch_conversation_by_remote_id!(app_id, remote_id) do
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
    if conversation.id != nil do
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
    {:ok, message} = Repo.transaction(fn ->
      conversation = fetch_conversation_by_remote_id!(app_id, remote_conversation_id)
      {:ok, conversation_user} = idempotently_add_user_to_conversation(conversation.id, user_id)

      other_user_ids
      |> Enum.each(&idempotently_add_user_with_remote_id_to_conversation(app_id, conversation.id, &1))

      %Message{
        id: Snowflakex.new!(),
        content: message,
        conversation_id: conversation.id,
        sender_id: user_id,
        conversation_user_id: conversation_user.id
      }
      |> Message.changeset
      |> Repo.insert!()
      |> Repo.preload(:sender)
      |> Repo.preload(:conversation_user)
    end)

    message
  end


  defp idempotently_add_user_with_remote_id_to_conversation(app_id, conversation_id, remote_user_id) do
    user = fetch_user_by_remote_id!(app_id, remote_user_id)
    idempotently_add_user_to_conversation(conversation_id, user.id)
  end

  # @doc """
  # Adds a user to a conversation.
  #
  # Calling this function multiple times has no (extra) effect.
  # """
  defp idempotently_add_user_to_conversation(conversation_id, user_id) do
    safe(fn ->
      Repo.transaction(fn ->
      user = Repo.get_by!(ConversationUser, conversation_id: conversation_id, user_id: user_id)
      if user do
        user
      else
        Repo.insert!(%ConversationUser{conversation_id: conversation_id, user_id: user_id})
      end
      end)
    end).()
    |> to_tagged_status
  end



  def update_username(user_id, remote_user_name) do
    Repo.transaction(fn ->
      User
      |> Repo.get!(user_id)
      |> Ecto.Changeset.change(name: remote_user_name)
      |> Repo.update()
    end)
    :ok
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

  def fetch_conversation_user_info(conversation_id, user_id) do
    safe(fn ->
      Repo.transaction(fn ->
        Planga.Chat.ConversationUser
        |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
      end)
    end).()
    |> to_tagged_status
  end

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

  def ban_chatter(conversation_id, user_id, duration_minutes) do
    import Ecto.Query
    now = DateTime.utc_now
    ban_end = Timex.add(now, Timex.Duration.from_minutes(duration_minutes))
    safe(fn ->
      Repo.transaction(fn ->
        Planga.Chat.ConversationUser
        bannable_conversation_users = from cu in Planga.Chat.ConversationUser, where: is_nil(cu.role)

        bannable_conversation_users
        |> Planga.Repo.get_by!(conversation_id: conversation_id, user_id: user_id)
        |> Ecto.Changeset.change(banned_until: ban_end)
        |> Repo.update!()
      end)
    end).()
    |> to_tagged_status
  end
end
