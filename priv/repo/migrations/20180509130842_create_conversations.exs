defmodule Plange.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :app_id, references("apps")
      add :remote_id, :string

      timestamps()
    end
    create index(:conversations, [:app_id, :remote_id], unique: true)
  end
end
