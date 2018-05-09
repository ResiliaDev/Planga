defmodule PlangeWeb.ConversationUsersView do
  use PlangeWeb, :view
  alias PlangeWeb.ConversationUsersView

  def render("index.json", %{conversations_users: conversations_users}) do
    %{data: render_many(conversations_users, ConversationUsersView, "conversation_users.json")}
  end

  def render("show.json", %{conversation_users: conversation_users}) do
    %{data: render_one(conversation_users, ConversationUsersView, "conversation_users.json")}
  end

  def render("conversation_users.json", %{conversation_users: conversation_users}) do
    %{id: conversation_users.id,
      conversation_id: conversation_users.conversation_id,
      user_id: conversation_users.user_id}
  end
end
