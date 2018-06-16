defmodule Planga.Chat do
  @moduledoc """
  The Chat context.
  """
  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser}

  def check_user_hmac(app_id, remote_user_id, base64_hmac) do
    app = Repo.get!(App, app_id)
    local_computed_hmac = :crypto.hmac(:sha256, app.secret_api_key, remote_user_id)
    local_computed_hmac == Base.decode64!(base64_hmac)
  end

  def update_user_name_if_hmac_correct(app_id, user_id, remote_user_name_hmac, remote_user_name) do
    if check_user_name_hmac(app_id, remote_user_name, remote_user_name_hmac) do
      Repo.transaction(fn ->
        Repo.get!(User, user_id)
        |> Ecto.Changeset.change(name: remote_user_name)
        |> Repo.update()
      end)
    end
    {:error, :invalid_hmac}
  end

  def check_user_name_hmac(app_id, user_name, base64_hmac) do
    app = Repo.get!(App, app_id)
    local_computed_hmac = :crypto.hmac(:sha256, app.secret_api_key, user_name)
    local_computed_hmac == Base.decode64!(base64_hmac)
  end

  def check_conversation_hmac(app_id, conversation_id, base64_hmac) do
    app = Repo.get!(App, app_id)
    local_computed_hmac = :crypto.hmac(:sha256, app.secret_api_key, conversation_id)
    local_computed_hmac == Base.decode64!(base64_hmac)
  end

  def get_user_by_remote_id!(app_id, remote_user_id, user_name \\ nil) do
    app = Repo.get!(App, app_id)
    {:ok, user} = Repo.insert(%User{app_id: app.id, remote_id: remote_user_id, name: user_name}, on_conflict: :nothing)
    if(user.id != nil) do
      user
    else
      Repo.get_by!(User, [app_id: app.id, remote_id: remote_user_id])
    end
  end

  def get_messages_by_conversation_id(conversation_id, sent_before_datetime \\ nil) do
    if(sent_before_datetime) do
      from(m in Message, where: m.conversation_id == ^conversation_id and m.inserted_at < ^sent_before_datetime, order_by: [desc: :id], limit: 10)
      # from(Message, where: [conversation_id: ^conversation_id], order_by: [desc: :inserted_at], limit: 10)
      # |> preload(:sender)
      |> Repo.all()
      |> Enum.map(&put_sender/1)
    else
      from(Message, where: [conversation_id: ^conversation_id], order_by: [desc: :id], limit: 20)
      # from(m in Message, where: m.conversation_id == ^conversation_id, limit: 20, order_by: [desc: :inserted_at])
      # |> preload(:sender)
      |> Repo.all()
      |> Enum.map(&put_sender/1)
    end
    |> IO.inspect
    # |> Enum.sort_by(&(&1.inserted_at))
  end

  # Temporary function until EctoMnesia supports `Ecto.Query.preload` statements.
  defp put_sender(message) do
    sender = Repo.get(User, message.sender_id)
    %Message{message | sender: sender}
  end

  def get_conversation_by_remote_id!(app_id, remote_id) do
    # query = [remote_id: remote_id]
    {:ok, {app, conversation}} = Repo.transaction(fn ->
      app = Repo.get!(App, app_id)
      conversation = Repo.get_by(Conversation, app_id: app.id, remote_id: remote_id)
      if conversation do
        {app, conversation}
      else
        conversation = Repo.insert!(%Conversation{app_id: app.id, remote_id: remote_id})
        {app, conversation}
      end
      # {:ok, conversation} = Repo.insert(%Conversation{app_id: app.id, remote_id: remote_id}, on_conflict: :nothing)
    end)
    # app = Repo.get!(App, app_id)
    # {:ok, conversation} = Repo.insert(%Conversation{app_id: app.id, remote_id: remote_id}, on_conflict: :nothing)
    if(conversation.id != nil) do
      conversation
    else
      Repo.get_by!(Conversation, app_id: app.id, remote_id: remote_id)
    end
  end

  def create_good_message(conversation_id, user_id, message) do
    Repo.insert!(
      %Message{
        content: message,
        conversation_id: conversation_id,
        sender_id: user_id
      })
      |> Repo.preload(:sender)
  end

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
end
