defmodule Planga.Chat.ConversationTopic do
  use Ecto.Schema
  import Ecto.Changeset


  schema "conversation_topics" do
    field :conversation_id, :id
    field :topic_id, :id

    timestamps()
  end

  @doc false
  def changeset(conversation_topic, attrs) do
    conversation_topic
    |> cast(attrs, [])
    |> validate_required([])
  end
end
