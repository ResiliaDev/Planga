defmodule Plange.Chat.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :name, :string
    field :remote_id, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :remote_id])
    |> validate_required([:name, :remote_id])
  end
end
