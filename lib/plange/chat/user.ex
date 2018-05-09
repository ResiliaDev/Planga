defmodule Plange.Chat.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    belongs_to :app, Plange.Chat.App
    field :name, :string
    field :remote_id, :string

    has_many :sent_messages, Plange.Chat.Message
    many_to_many :conversations, Plange.Chat.Conversation, join_through: "conversations_users"

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :remote_id])
    |> validate_required([:name, :remote_id])
  end
end
