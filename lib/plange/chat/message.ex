defmodule Plange.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset


  schema "message" do
    belongs_to :sender, Plange.Chat.User
    belongs_to :conversation, Plange.Chat.Conversation
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
