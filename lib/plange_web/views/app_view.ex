defmodule PlangeWeb.AppView do
  use PlangeWeb, :view
  alias PlangeWeb.AppView

  def render("index.json", %{apps: apps}) do
    %{data: render_many(apps, AppView, "app.json")}
  end

  def render("show.json", %{app: app}) do
    %{data: render_one(app, AppView, "app.json")}
  end

  def render("app.json", %{app: app}) do
    %{id: app.id,
      name: app.name,
      secret_api_key: app.secret_api_key}
  end
end
