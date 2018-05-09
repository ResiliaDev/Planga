defmodule PlangeWeb.PageController do
  use PlangeWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
