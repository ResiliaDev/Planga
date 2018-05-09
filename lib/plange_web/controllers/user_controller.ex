defmodule PlangeWeb.UserController do
  use PlangeWeb, :controller

  alias Plange.Chat
  alias Plange.Chat.User

  action_fallback PlangeWeb.FallbackController

  def index(conn, _params) do
    users = Chat.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Chat.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Chat.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Chat.get_user!(id)

    with {:ok, %User{} = user} <- Chat.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Chat.get_user!(id)
    with {:ok, %User{}} <- Chat.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
