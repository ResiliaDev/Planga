defmodule Planga.Chat.APIKeyPair do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:public_id, :string, []}
  schema "api_key_pairs" do
    field :secret_key, :string
    field :enabled, :boolean
    belongs_to :app, Planga.Chat.App

    timestamps()
  end

  @doc false
  def changeset(api_key_pair, attrs) do
    api_key_pair
    |> cast(attrs, [:public_id, :secret_key])
    |> validate_required([:public_id, :secret_key])
  end
end
