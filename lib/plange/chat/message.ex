defmodule Planga.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset


  schema "message" do
    belongs_to :sender, Planga.Chat.User
    belongs_to :conversation, Planga.Chat.Conversation
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender_id, :content, :channel_id])
    |> validate_required([:sender_id, :content, :channel_id])
  end
end
