defmodule Planga.Repo.Migrations.AddDeletedAtToMessages do
  use Ecto.Migration

  def change do
    alter table(:message) do
      add :deleted_at, :utc_datetime
    end
  end
end
