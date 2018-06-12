defmodule PlangaWeb.MessageControllerTest do
  use PlangaWeb.ConnCase

  alias Planga.Chat
  alias Planga.Chat.Message

  @create_attrs %{channel_id: 42, content: "some content", sender_id: 42}
  @update_attrs %{channel_id: 43, content: "some updated content", sender_id: 43}
  @invalid_attrs %{channel_id: nil, content: nil, sender_id: nil}

  def fixture(:message) do
    {:ok, message} = Chat.create_message(@create_attrs)
    message
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all message", %{conn: conn} do
      conn = get conn, message_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create message" do
    test "renders message when data is valid", %{conn: conn} do
      conn = post conn, message_path(conn, :create), message: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, message_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "channel_id" => 42,
        "content" => "some content",
        "sender_id" => 42}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, message_path(conn, :create), message: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update message" do
    setup [:create_message]

    test "renders message when data is valid", %{conn: conn, message: %Message{id: id} = message} do
      conn = put conn, message_path(conn, :update, message), message: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, message_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "channel_id" => 43,
        "content" => "some updated content",
        "sender_id" => 43}
    end

    test "renders errors when data is invalid", %{conn: conn, message: message} do
      conn = put conn, message_path(conn, :update, message), message: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete message" do
    setup [:create_message]

    test "deletes chosen message", %{conn: conn, message: message} do
      conn = delete conn, message_path(conn, :delete, message)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, message_path(conn, :show, message)
      end
    end
  end

  defp create_message(_) do
    message = fixture(:message)
    {:ok, message: message}
  end
end
