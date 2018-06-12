defmodule Planga.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:message) do
      add :sender_id, :integer # references("users")
      add :conversation_id, :integer # references("conversations")
      add :content, :string

      timestamps()
    end
  end
end
