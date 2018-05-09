defmodule Plange.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Plange.Repo

  alias Plange.Chat.User

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

  alias Plange.Chat.Message

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

  alias Plange.Chat.Conversation

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

  alias Plange.Chat.ConversationUsers

  @doc """
  Returns the list of conversations_users.

  ## Examples

      iex> list_conversations_users()
      [%ConversationUsers{}, ...]

  """
  def list_conversations_users do
    Repo.all(ConversationUsers)
  end

  @doc """
  Gets a single conversation_users.

  Raises `Ecto.NoResultsError` if the Conversation users does not exist.

  ## Examples

      iex> get_conversation_users!(123)
      %ConversationUsers{}

      iex> get_conversation_users!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation_users!(id), do: Repo.get!(ConversationUsers, id)

  @doc """
  Creates a conversation_users.

  ## Examples

      iex> create_conversation_users(%{field: value})
      {:ok, %ConversationUsers{}}

      iex> create_conversation_users(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation_users(attrs \\ %{}) do
    %ConversationUsers{}
    |> ConversationUsers.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation_users.

  ## Examples

      iex> update_conversation_users(conversation_users, %{field: new_value})
      {:ok, %ConversationUsers{}}

      iex> update_conversation_users(conversation_users, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation_users(%ConversationUsers{} = conversation_users, attrs) do
    conversation_users
    |> ConversationUsers.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ConversationUsers.

  ## Examples

      iex> delete_conversation_users(conversation_users)
      {:ok, %ConversationUsers{}}

      iex> delete_conversation_users(conversation_users)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation_users(%ConversationUsers{} = conversation_users) do
    Repo.delete(conversation_users)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation_users changes.

  ## Examples

      iex> change_conversation_users(conversation_users)
      %Ecto.Changeset{source: %ConversationUsers{}}

  """
  def change_conversation_users(%ConversationUsers{} = conversation_users) do
    ConversationUsers.changeset(conversation_users, %{})
  end

  alias Plange.Chat.App

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

  def create_message(conversation_id, username, message) do
    Repo.insert!(
      %Message{
        content: message,
        conversation_id: conversation_id,
      })

  end
end
