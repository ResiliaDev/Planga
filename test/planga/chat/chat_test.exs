defmodule Planga.ChatTest do
  use Planga.DataCase

  alias Planga.Chat

  describe "users" do
    alias Planga.Chat.User

    @valid_attrs %{name: "some name", remote_id: "some remote_id"}
    @update_attrs %{name: "some updated name", remote_id: "some updated remote_id"}
    @invalid_attrs %{name: nil, remote_id: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Chat.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Chat.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Chat.create_user(@valid_attrs)
      assert user.name == "some name"
      assert user.remote_id == "some remote_id"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Chat.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.name == "some updated name"
      assert user.remote_id == "some updated remote_id"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_user(user, @invalid_attrs)
      assert user == Chat.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Chat.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Chat.change_user(user)
    end
  end

  describe "message" do
    alias Planga.Chat.Message

    @valid_attrs %{channel_id: 42, content: "some content", sender_id: 42}
    @update_attrs %{channel_id: 43, content: "some updated content", sender_id: 43}
    @invalid_attrs %{channel_id: nil, content: nil, sender_id: nil}

    def message_fixture(attrs \\ %{}) do
      {:ok, message} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_message()

      message
    end

    test "list_message/0 returns all message" do
      message = message_fixture()
      assert Chat.list_message() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Chat.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      assert {:ok, %Message{} = message} = Chat.create_message(@valid_attrs)
      assert message.channel_id == 42
      assert message.content == "some content"
      assert message.sender_id == 42
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, message} = Chat.update_message(message, @update_attrs)
      assert %Message{} = message
      assert message.channel_id == 43
      assert message.content == "some updated content"
      assert message.sender_id == 43
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(message, @invalid_attrs)
      assert message == Chat.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Chat.change_message(message)
    end
  end

  describe "conversations" do
    alias Planga.Chat.Conversation

    @valid_attrs %{remote_id: "some remote_id"}
    @update_attrs %{remote_id: "some updated remote_id"}
    @invalid_attrs %{remote_id: nil}

    def conversation_fixture(attrs \\ %{}) do
      {:ok, conversation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_conversation()

      conversation
    end

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Chat.list_conversations() == [conversation]
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Chat.get_conversation!(conversation.id) == conversation
    end

    test "create_conversation/1 with valid data creates a conversation" do
      assert {:ok, %Conversation{} = conversation} = Chat.create_conversation(@valid_attrs)
      assert conversation.remote_id == "some remote_id"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_conversation(@invalid_attrs)
    end

    test "update_conversation/2 with valid data updates the conversation" do
      conversation = conversation_fixture()
      assert {:ok, conversation} = Chat.update_conversation(conversation, @update_attrs)
      assert %Conversation{} = conversation
      assert conversation.remote_id == "some updated remote_id"
    end

    test "update_conversation/2 with invalid data returns error changeset" do
      conversation = conversation_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_conversation(conversation, @invalid_attrs)
      assert conversation == Chat.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = conversation_fixture()
      assert {:ok, %Conversation{}} = Chat.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset" do
      conversation = conversation_fixture()
      assert %Ecto.Changeset{} = Chat.change_conversation(conversation)
    end
  end

  describe "conversations_users" do
    alias Planga.Chat.ConversationUsers

    @valid_attrs %{conversation_id: 42, user_id: 42}
    @update_attrs %{conversation_id: 43, user_id: 43}
    @invalid_attrs %{conversation_id: nil, user_id: nil}

    def conversation_users_fixture(attrs \\ %{}) do
      {:ok, conversation_users} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_conversation_users()

      conversation_users
    end

    test "list_conversations_users/0 returns all conversations_users" do
      conversation_users = conversation_users_fixture()
      assert Chat.list_conversations_users() == [conversation_users]
    end

    test "get_conversation_users!/1 returns the conversation_users with given id" do
      conversation_users = conversation_users_fixture()
      assert Chat.get_conversation_users!(conversation_users.id) == conversation_users
    end

    test "create_conversation_users/1 with valid data creates a conversation_users" do
      assert {:ok, %ConversationUsers{} = conversation_users} = Chat.create_conversation_users(@valid_attrs)
      assert conversation_users.conversation_id == 42
      assert conversation_users.user_id == 42
    end

    test "create_conversation_users/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_conversation_users(@invalid_attrs)
    end

    test "update_conversation_users/2 with valid data updates the conversation_users" do
      conversation_users = conversation_users_fixture()
      assert {:ok, conversation_users} = Chat.update_conversation_users(conversation_users, @update_attrs)
      assert %ConversationUsers{} = conversation_users
      assert conversation_users.conversation_id == 43
      assert conversation_users.user_id == 43
    end

    test "update_conversation_users/2 with invalid data returns error changeset" do
      conversation_users = conversation_users_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_conversation_users(conversation_users, @invalid_attrs)
      assert conversation_users == Chat.get_conversation_users!(conversation_users.id)
    end

    test "delete_conversation_users/1 deletes the conversation_users" do
      conversation_users = conversation_users_fixture()
      assert {:ok, %ConversationUsers{}} = Chat.delete_conversation_users(conversation_users)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_conversation_users!(conversation_users.id) end
    end

    test "change_conversation_users/1 returns a conversation_users changeset" do
      conversation_users = conversation_users_fixture()
      assert %Ecto.Changeset{} = Chat.change_conversation_users(conversation_users)
    end
  end

  describe "apps" do
    alias Planga.Chat.App

    @valid_attrs %{name: "some name", secret_api_key: "some secret_api_key"}
    @update_attrs %{name: "some updated name", secret_api_key: "some updated secret_api_key"}
    @invalid_attrs %{name: nil, secret_api_key: nil}

    def app_fixture(attrs \\ %{}) do
      {:ok, app} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_app()

      app
    end

    test "list_apps/0 returns all apps" do
      app = app_fixture()
      assert Chat.list_apps() == [app]
    end

    test "get_app!/1 returns the app with given id" do
      app = app_fixture()
      assert Chat.get_app!(app.id) == app
    end

    test "create_app/1 with valid data creates a app" do
      assert {:ok, %App{} = app} = Chat.create_app(@valid_attrs)
      assert app.name == "some name"
      assert app.secret_api_key == "some secret_api_key"
    end

    test "create_app/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_app(@invalid_attrs)
    end

    test "update_app/2 with valid data updates the app" do
      app = app_fixture()
      assert {:ok, app} = Chat.update_app(app, @update_attrs)
      assert %App{} = app
      assert app.name == "some updated name"
      assert app.secret_api_key == "some updated secret_api_key"
    end

    test "update_app/2 with invalid data returns error changeset" do
      app = app_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_app(app, @invalid_attrs)
      assert app == Chat.get_app!(app.id)
    end

    test "delete_app/1 deletes the app" do
      app = app_fixture()
      assert {:ok, %App{}} = Chat.delete_app(app)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_app!(app.id) end
    end

    test "change_app/1 returns a app changeset" do
      app = app_fixture()
      assert %Ecto.Changeset{} = Chat.change_app(app)
    end
  end

  describe "topics" do
    alias Planga.Chat.Topic

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def topic_fixture(attrs \\ %{}) do
      {:ok, topic} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_topic()

      topic
    end

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      assert Chat.list_topics() == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = topic_fixture()
      assert Chat.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic" do
      assert {:ok, %Topic{} = topic} = Chat.create_topic(@valid_attrs)
      assert topic.name == "some name"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_topic(@invalid_attrs)
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = topic_fixture()
      assert {:ok, topic} = Chat.update_topic(topic, @update_attrs)
      assert %Topic{} = topic
      assert topic.name == "some updated name"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_topic(topic, @invalid_attrs)
      assert topic == Chat.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Chat.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Chat.change_topic(topic)
    end
  end

  describe "conversation_topics" do
    alias Planga.Chat.ConversationTopic

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def conversation_topic_fixture(attrs \\ %{}) do
      {:ok, conversation_topic} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_conversation_topic()

      conversation_topic
    end

    test "list_conversation_topics/0 returns all conversation_topics" do
      conversation_topic = conversation_topic_fixture()
      assert Chat.list_conversation_topics() == [conversation_topic]
    end

    test "get_conversation_topic!/1 returns the conversation_topic with given id" do
      conversation_topic = conversation_topic_fixture()
      assert Chat.get_conversation_topic!(conversation_topic.id) == conversation_topic
    end

    test "create_conversation_topic/1 with valid data creates a conversation_topic" do
      assert {:ok, %ConversationTopic{} = conversation_topic} = Chat.create_conversation_topic(@valid_attrs)
    end

    test "create_conversation_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_conversation_topic(@invalid_attrs)
    end

    test "update_conversation_topic/2 with valid data updates the conversation_topic" do
      conversation_topic = conversation_topic_fixture()
      assert {:ok, conversation_topic} = Chat.update_conversation_topic(conversation_topic, @update_attrs)
      assert %ConversationTopic{} = conversation_topic
    end

    test "update_conversation_topic/2 with invalid data returns error changeset" do
      conversation_topic = conversation_topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_conversation_topic(conversation_topic, @invalid_attrs)
      assert conversation_topic == Chat.get_conversation_topic!(conversation_topic.id)
    end

    test "delete_conversation_topic/1 deletes the conversation_topic" do
      conversation_topic = conversation_topic_fixture()
      assert {:ok, %ConversationTopic{}} = Chat.delete_conversation_topic(conversation_topic)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_conversation_topic!(conversation_topic.id) end
    end

    test "change_conversation_topic/1 returns a conversation_topic changeset" do
      conversation_topic = conversation_topic_fixture()
      assert %Ecto.Changeset{} = Chat.change_conversation_topic(conversation_topic)
    end
  end
end
