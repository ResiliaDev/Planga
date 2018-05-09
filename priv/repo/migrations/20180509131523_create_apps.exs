defmodule Plange.Repo.Migrations.CreateApps do
  use Ecto.Migration

  def change do
    create table(:apps) do
      add :name, :string
      add :secret_api_key, :string

      timestamps()
    end

  end
end
