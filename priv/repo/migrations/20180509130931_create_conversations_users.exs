defmodule Plange.Repo.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    create table(:conversations_users) do
      add :conversation_id, references("conversations")
      add :app_id, references("apps")
      add :user_id, references("users")

    end

  end
end
