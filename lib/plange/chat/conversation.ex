defmodule Plange.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset


  schema "conversations" do
    field :remote_id, :string
    belongs_to :app, Plange.Chat.App
    many_to_many :users, Plange.Chat.User, join_through: "conversations_users"

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:remote_id])
    |> validate_required([:remote_id])
  end
end
