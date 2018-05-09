defmodule Plange.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:message) do
      add :sender_id, references("users")
      add :conversation_id, references("conversations")
      add :content, :string

      timestamps()
    end

  end
end
