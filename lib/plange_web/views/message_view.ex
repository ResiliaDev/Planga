defmodule PlangeWeb.MessageView do
  use PlangeWeb, :view
  alias PlangeWeb.MessageView

  def render("index.json", %{message: message}) do
    %{data: render_many(message, MessageView, "message.json")}
  end

  def render("show.json", %{message: message}) do
    %{data: render_one(message, MessageView, "message.json")}
  end

  def render("message.json", %{message: message}) do
    %{id: message.id,
      sender_id: message.sender_id,
      content: message.content,
      channel_id: message.channel_id}
  end
end
