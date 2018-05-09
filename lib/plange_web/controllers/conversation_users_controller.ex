defmodule PlangeWeb.ConversationUsersController do
  use PlangeWeb, :controller

  alias Plange.Chat
  alias Plange.Chat.ConversationUsers

  action_fallback PlangeWeb.FallbackController

  def index(conn, _params) do
    conversations_users = Chat.list_conversations_users()
    render(conn, "index.json", conversations_users: conversations_users)
  end

  def create(conn, %{"conversation_users" => conversation_users_params}) do
    with {:ok, %ConversationUsers{} = conversation_users} <- Chat.create_conversation_users(conversation_users_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", conversation_users_path(conn, :show, conversation_users))
      |> render("show.json", conversation_users: conversation_users)
    end
  end

  def show(conn, %{"id" => id}) do
    conversation_users = Chat.get_conversation_users!(id)
    render(conn, "show.json", conversation_users: conversation_users)
  end

  def update(conn, %{"id" => id, "conversation_users" => conversation_users_params}) do
    conversation_users = Chat.get_conversation_users!(id)

    with {:ok, %ConversationUsers{} = conversation_users} <- Chat.update_conversation_users(conversation_users, conversation_users_params) do
      render(conn, "show.json", conversation_users: conversation_users)
    end
  end

  def delete(conn, %{"id" => id}) do
    conversation_users = Chat.get_conversation_users!(id)
    with {:ok, %ConversationUsers{}} <- Chat.delete_conversation_users(conversation_users) do
      send_resp(conn, :no_content, "")
    end
  end
end
