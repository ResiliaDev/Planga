defmodule Planga.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset


  schema "conversations" do
    field :remote_id, :string
    belongs_to :app, Planga.Chat.App
    many_to_many :users, Planga.Chat.User, join_through: "conversations_users"

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:remote_id])
    |> validate_required([:remote_id])
  end
end
