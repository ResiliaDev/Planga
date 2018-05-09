defmodule Plange.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset


  schema "message" do
    field :channel_id, :integer
    field :content, :string
    field :sender_id, :integer

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender_id, :content, :channel_id])
    |> validate_required([:sender_id, :content, :channel_id])
  end
end
