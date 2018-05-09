defmodule Plange.ChatTest do
  use Plange.DataCase

  alias Plange.Chat

  describe "users" do
    alias Plange.Chat.User

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
    alias Plange.Chat.Message

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
    alias Plange.Chat.Conversation

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
    alias Plange.Chat.ConversationUsers

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
end
