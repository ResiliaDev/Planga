defmodule Plange.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :remote_id, :string
      add :app_id, references("apps")

      timestamps()
    end

  end
end
