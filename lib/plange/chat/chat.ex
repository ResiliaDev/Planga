defmodule Plange.Chat do
  @moduledoc """
  The Chat context.
  """
  import Ecto.Query, warn: false
  alias Plange.Repo
  alias Plange.Chat.{User, Message, Conversation, App}

  def check_user_hmac(app_id, remote_user_id, base64_hmac) do
    app = Repo.get!(App, app_id)
    local_computed_hmac = :crypto.hmac(:sha256, app.secret_api_key, remote_user_id)
    local_computed_hmac == Base.decode64!(base64_hmac)
  end

  def update_user_name_if_hmac_correct(app_id, user_id, remote_user_name_hmac, remote_user_name) do
    if check_user_name_hmac(app_id, remote_user_name, remote_user_name_hmac) do
      user = Repo.get!(User, user_id)
      user
      |> Ecto.Changeset.change(name: remote_user_name)
      |> Repo.update()
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
      from(m in Message, where: m.conversation_id == ^conversation_id and m.inserted_at < ^sent_before_datetime, order_by: [desc: :inserted_at], limit: 10)
      |> preload(:sender)
      |> Repo.all()
    else
      from(m in Message, where: m.conversation_id == ^conversation_id, limit: 20, order_by: [desc: :inserted_at])
      |> preload(:sender)
      |> Repo.all()
    end
  end

  def get_conversation_by_remote_id!(app_id, remote_id) do
    # query = [remote_id: remote_id]
    app = Repo.get!(App, app_id)
    {:ok, conversation} = Repo.insert(%Conversation{app_id: app.id, remote_id: remote_id}, on_conflict: :nothing)
    IO.inspect({"CONVERSATION: ", conversation, conversation.id})
    if(conversation.id != nil) do
      IO.inspect({"CONVERSATION2: ", conversation, conversation.id})
      conversation
    else
      IO.inspect({"CONVERSATION3: ", conversation})
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
    IO.inspect("TODO", label: :idempotently_add_user_to_conversation)
    # Repo.get!(User, user_id)
    # |> Repo.preload(:conversations)
    # |> Ecto.Changeset.change()
    # |> Ecto.Changeset.put_assoc(:conversations, [conversation_id])
    # |> Repo.update!
  end
end


defmodule Plange.ChatOld do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Plange.Repo

  alias Plange.Chat.{User, Message, Conversation, App}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc """
  Returns the list of message.

  ## Examples

      iex> list_message()
      [%Message{}, ...]

  """
  def list_message do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{source: %Message{}}

  """
  def change_message(%Message{} = message) do
    Message.changeset(message, %{})
  end

  @doc """
  Returns the list of conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Repo.all(Conversation)
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id), do: Repo.get!(Conversation, id)

  @doc """
  Creates a conversation.

  ## Examples

      iex> create_conversation(%{field: value})
      {:ok, %Conversation{}}

      iex> create_conversation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation.

  ## Examples

      iex> update_conversation(conversation, %{field: new_value})
      {:ok, %Conversation{}}

      iex> update_conversation(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Conversation.

  ## Examples

      iex> delete_conversation(conversation)
      {:ok, %Conversation{}}

      iex> delete_conversation(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{source: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation) do
    Conversation.changeset(conversation, %{})
  end

  @doc """
  Returns the list of apps.

  ## Examples

      iex> list_apps()
      [%App{}, ...]

  """
  def list_apps do
    Repo.all(App)
  end

  @doc """
  Gets a single app.

  Raises `Ecto.NoResultsError` if the App does not exist.

  ## Examples

      iex> get_app!(123)
      %App{}

      iex> get_app!(456)
      ** (Ecto.NoResultsError)

  """
  def get_app!(id), do: Repo.get!(App, id)

  @doc """
  Creates a app.

  ## Examples

      iex> create_app(%{field: value})
      {:ok, %App{}}

      iex> create_app(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app(attrs \\ %{}) do
    %App{}
    |> App.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a app.

  ## Examples

      iex> update_app(app, %{field: new_value})
      {:ok, %App{}}

      iex> update_app(app, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%App{} = app, attrs) do
    app
    |> App.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a App.

  ## Examples

      iex> delete_app(app)
      {:ok, %App{}}

      iex> delete_app(app)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app(%App{} = app) do
    Repo.delete(app)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app changes.

  ## Examples

      iex> change_app(app)
      %Ecto.Changeset{source: %App{}}

  """
  def change_app(%App{} = app) do
    App.changeset(app, %{})
  end

  # ACTUAL CODE

  def get_or_create_user(%User{} = user, attrs) do
    user
    |> App.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def get_or_create_conversation(%Conversation{} = conv, attrs) do
    conv
    |> App.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def get_conversation_by_remote_id!(remote_id) do
    query = [remote_id: remote_id]
    Repo.get_by!(Conversation, query, [])
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

  def get_messages_by_conversation_id(conversation_id) do
    Repo.all(Message |> preload(:sender), where: [conversation_id: conversation_id])
  end

  @deprecated
  def get_user_by_name(app_id, username) do
    Repo.get_by!(User, [name: username] )
  end

  def get_user_by_remote_id!(app_id, remote_id) do
    Repo.get_by!(User, [app_id: app_id, remote_id: remote_id] )
  end
end
