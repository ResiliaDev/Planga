defmodule Planga.Repo.Migrations.AddDeletedAtToMessages do
  use Ecto.Migration

  def change do
    alter table(:message) do
      add :deleted_at, :datetime, default: nil
    end
  end
end
