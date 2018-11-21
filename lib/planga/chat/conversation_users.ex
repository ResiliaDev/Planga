defmodule Planga.Chat.ConversationUser do
  @moduledoc """
  This schema is the relation between a user
  and a given conversation.
  """
  use Ecto.Schema
  import Ecto.Changeset


  schema "conversations_users" do
    field :conversation_id, :integer
    field :user_id, :integer
    field :role, :string, default: ""
    field :banned_until, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(conversation_user, attrs) do
    conversation_user
    |> cast(attrs, [:conversation_id, :user_id])
    |> validate_required([:conversation_id, :user_id])
  end
end
