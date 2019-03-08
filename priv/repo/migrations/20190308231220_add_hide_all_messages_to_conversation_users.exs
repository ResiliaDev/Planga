defmodule Planga.Repo.Migrations.AddHideAllMessagesToConversationUsers do
  use Ecto.Migration

  def change do
    alter table(:conversations_users) do
      add :hide_all_messages, :boolean
    end
  end
end
