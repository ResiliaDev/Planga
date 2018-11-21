defmodule Planga.Repo.Migrations.AddRoleToConversationsUsers do
  use Ecto.Migration

  def change do
    alter table(:conversations_users) do
      add :role, :string
    end
  end
end
