defmodule Planga.Repo.Migrations.AddsConversationUsersToMessages do
  use Ecto.Migration

  def change do
    alter table(:message) do
      add :conversation_user_id, references(:conversations_users)
    end
  end
end
