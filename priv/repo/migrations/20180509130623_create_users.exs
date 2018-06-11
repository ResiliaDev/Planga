defmodule Plange.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :remote_id, :string
      add :app_id, :integer #references("apps")

      timestamps()
    end
    create index(:users, [:app_id, :remote_id], unique: true)

  end
end
