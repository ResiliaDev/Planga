defmodule Planga.Repo.Migrations.AddUuidToChatMessages do
  use Ecto.Migration

  def change do
    alter table(:message) do
      add :uuid, :binary_id
    end

  end
end
