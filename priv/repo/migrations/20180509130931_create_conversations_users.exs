defmodule Plange.Repo.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    create table(:conversations_users) do
      add :app_id, references("apps")

      add :conversation_id, references("conversations")
      add :user_id, references("users")
    end

    create unique_index(:conversations_users, [:conversation_id, :user_id])
  end
end
