defmodule Planga.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :app_id, references(:apps, on_delete: :nothing)

      timestamps()
    end

    create index(:topics, [:app_id])
  end
end
