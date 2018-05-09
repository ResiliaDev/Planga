defmodule PlangeWeb.AppController do
  use PlangeWeb, :controller

  alias Plange.Chat
  alias Plange.Chat.App

  action_fallback PlangeWeb.FallbackController

  def index(conn, _params) do
    apps = Chat.list_apps()
    render(conn, "index.json", apps: apps)
  end

  def create(conn, %{"app" => app_params}) do
    with {:ok, %App{} = app} <- Chat.create_app(app_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", app_path(conn, :show, app))
      |> render("show.json", app: app)
    end
  end

  def show(conn, %{"id" => id}) do
    app = Chat.get_app!(id)
    render(conn, "show.json", app: app)
  end

  def update(conn, %{"id" => id, "app" => app_params}) do
    app = Chat.get_app!(id)

    with {:ok, %App{} = app} <- Chat.update_app(app, app_params) do
      render(conn, "show.json", app: app)
    end
  end

  def delete(conn, %{"id" => id}) do
    app = Chat.get_app!(id)
    with {:ok, %App{}} <- Chat.delete_app(app) do
      send_resp(conn, :no_content, "")
    end
  end
end
