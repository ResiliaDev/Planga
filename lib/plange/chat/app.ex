defmodule Plange.Chat.App do
  use Ecto.Schema
  import Ecto.Changeset


  schema "apps" do
    field :name, :string
    field :secret_api_key, :string

    has_many :conversations, Plange.Chat.Conversation
    has_many :users, Plange.Chat.User

    timestamps()
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name, :secret_api_key])
    |> validate_required([:name, :secret_api_key])
  end
end
