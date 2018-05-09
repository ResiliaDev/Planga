defmodule Plange.Repo.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    create table(:conversations_users) do
      add :conversation_id, references: "conversations"
      add :user_id, references: "users"

      timestamps()
    end

  end
end
