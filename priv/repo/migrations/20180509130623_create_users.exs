defmodule Plange.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :remote_id, :string

      timestamps()
    end

  end
end
