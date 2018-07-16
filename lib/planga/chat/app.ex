defmodule Planga.Chat.App do
  use Ecto.Schema
  import Ecto.Changeset


  schema "apps" do
    field :name, :string
    has_many :api_key_pairs, Planga.Chat.APIKeyPair

    has_many :conversations, Planga.Chat.Conversation
    has_many :users, Planga.Chat.User

    timestamps()
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
