defmodule PlangeWeb.MessageController do
  use PlangeWeb, :controller

  alias Plange.Chat
  alias Plange.Chat.Message

  action_fallback PlangeWeb.FallbackController

  def index(conn, _params) do
    message = Chat.list_message()
    render(conn, "index.json", message: message)
  end

  def create(conn, %{"message" => message_params}) do
    with {:ok, %Message{} = message} <- Chat.create_message(message_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", message_path(conn, :show, message))
      |> render("show.json", message: message)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Chat.get_message!(id)
    render(conn, "show.json", message: message)
  end

  def update(conn, %{"id" => id, "message" => message_params}) do
    message = Chat.get_message!(id)

    with {:ok, %Message{} = message} <- Chat.update_message(message, message_params) do
      render(conn, "show.json", message: message)
    end
  end

  def delete(conn, %{"id" => id}) do
    message = Chat.get_message!(id)
    with {:ok, %Message{}} <- Chat.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end
end
