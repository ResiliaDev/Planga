defmodule Planga.Repo.Migrations.CreateConversationTopics do
  use Ecto.Migration

  def change do
    create table(:conversation_topics) do
      add :conversation_id, references(:conversations, on_delete: :nothing)
      add :topic_id, references(:topics, on_delete: :nothing)

      timestamps()
    end

    create index(:conversation_topics, [:conversation_id])
    create index(:conversation_topics, [:topic_id])
  end
end
