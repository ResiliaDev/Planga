defmodule Plange.Repo.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    create table(:conversations_users) do
      add :conversation_id, :integer
      add :user_id, :integer

      timestamps()
    end

  end
end
