defmodule PlangeWeb.ConversationView do
  use PlangeWeb, :view
  alias PlangeWeb.ConversationView

  def render("index.json", %{conversations: conversations}) do
    %{data: render_many(conversations, ConversationView, "conversation.json")}
  end

  def render("show.json", %{conversation: conversation}) do
    %{data: render_one(conversation, ConversationView, "conversation.json")}
  end

  def render("conversation.json", %{conversation: conversation}) do
    %{id: conversation.id,
      remote_id: conversation.remote_id}
  end
end
