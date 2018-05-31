defmodule PlangeWeb.PageController do
  use PlangeWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def example(conn, _params) do
    render conn, "example.html"
  end

  def example2(conn, _params) do
    render conn, "second_example.html"
  end
end
