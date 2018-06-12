defmodule PlangaWeb.ConversationUsersControllerTest do
  use PlangaWeb.ConnCase

  alias Planga.Chat
  alias Planga.Chat.ConversationUsers

  @create_attrs %{conversation_id: 42, user_id: 42}
  @update_attrs %{conversation_id: 43, user_id: 43}
  @invalid_attrs %{conversation_id: nil, user_id: nil}

  def fixture(:conversation_users) do
    {:ok, conversation_users} = Chat.create_conversation_users(@create_attrs)
    conversation_users
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all conversations_users", %{conn: conn} do
      conn = get conn, conversation_users_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create conversation_users" do
    test "renders conversation_users when data is valid", %{conn: conn} do
      conn = post conn, conversation_users_path(conn, :create), conversation_users: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, conversation_users_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "conversation_id" => 42,
        "user_id" => 42}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, conversation_users_path(conn, :create), conversation_users: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update conversation_users" do
    setup [:create_conversation_users]

    test "renders conversation_users when data is valid", %{conn: conn, conversation_users: %ConversationUsers{id: id} = conversation_users} do
      conn = put conn, conversation_users_path(conn, :update, conversation_users), conversation_users: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, conversation_users_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "conversation_id" => 43,
        "user_id" => 43}
    end

    test "renders errors when data is invalid", %{conn: conn, conversation_users: conversation_users} do
      conn = put conn, conversation_users_path(conn, :update, conversation_users), conversation_users: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete conversation_users" do
    setup [:create_conversation_users]

    test "deletes chosen conversation_users", %{conn: conn, conversation_users: conversation_users} do
      conn = delete conn, conversation_users_path(conn, :delete, conversation_users)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, conversation_users_path(conn, :show, conversation_users)
      end
    end
  end

  defp create_conversation_users(_) do
    conversation_users = fixture(:conversation_users)
    {:ok, conversation_users: conversation_users}
  end
end
