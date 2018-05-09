defmodule Plange.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:message) do
      add :sender_id, :integer
      add :content, :string
      add :channel_id, :integer

      timestamps()
    end

  end
end
