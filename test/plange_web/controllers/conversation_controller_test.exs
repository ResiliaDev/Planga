defmodule PlangeWeb.ConversationControllerTest do
  use PlangeWeb.ConnCase

  alias Plange.Chat
  alias Plange.Chat.Conversation

  @create_attrs %{remote_id: "some remote_id"}
  @update_attrs %{remote_id: "some updated remote_id"}
  @invalid_attrs %{remote_id: nil}

  def fixture(:conversation) do
    {:ok, conversation} = Chat.create_conversation(@create_attrs)
    conversation
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all conversations", %{conn: conn} do
      conn = get conn, conversation_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create conversation" do
    test "renders conversation when data is valid", %{conn: conn} do
      conn = post conn, conversation_path(conn, :create), conversation: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, conversation_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "remote_id" => "some remote_id"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, conversation_path(conn, :create), conversation: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update conversation" do
    setup [:create_conversation]

    test "renders conversation when data is valid", %{conn: conn, conversation: %Conversation{id: id} = conversation} do
      conn = put conn, conversation_path(conn, :update, conversation), conversation: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, conversation_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "remote_id" => "some updated remote_id"}
    end

    test "renders errors when data is invalid", %{conn: conn, conversation: conversation} do
      conn = put conn, conversation_path(conn, :update, conversation), conversation: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete conversation" do
    setup [:create_conversation]

    test "deletes chosen conversation", %{conn: conn, conversation: conversation} do
      conn = delete conn, conversation_path(conn, :delete, conversation)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, conversation_path(conn, :show, conversation)
      end
    end
  end

  defp create_conversation(_) do
    conversation = fixture(:conversation)
    {:ok, conversation: conversation}
  end
end
