defmodule Planga.Repo.Migrations.AddRoleToConversationsUsers do
  use Ecto.Migration

  def change do
    alter table(:message) do
      add :role, :string
    end
  end
end
