defmodule Planga.Repo.Migrations.AddBannedUntilToConversationsUsers do
  use Ecto.Migration

  def change do
    alter table(:conversations_users) do
      add :banned_until, :utc_datetime
    end
  end
end
