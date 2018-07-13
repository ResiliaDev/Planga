defmodule Planga.Chat.Topic do
  use Ecto.Schema
  import Ecto.Changeset


  schema "topics" do
    field :name, :string
    field :app_id, :id

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
