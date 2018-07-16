defmodule Planga.Repo.Migrations.CreateApiKeyPairs do
  use Ecto.Migration

  def change do
    create table(:api_key_pairs, primary_key: false) do
      add :public_id, :string, primary_key: true
      add :secret_key, :string
      add :app_id, references(:apps, on_delete: :nothing)

      timestamps()
    end

    create index(:api_key_pairs, [:app_id])
  end
end
