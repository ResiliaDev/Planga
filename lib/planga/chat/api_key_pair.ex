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
    |> cast(attrs, [:public_id, :secret_key, :app_id])
    |> validate_required([:public_id, :secret_key, :app_id])
  end

  def from_json(api_key_pair \\ %__MODULE__{}, json) do
    api_key_pair
    |> changeset(
      %{
        enabled: json["active"],
        public_id: json["public_id"],
        secret_key: json["private_key"],
        app_id: json["app_id"]
      }
    )
  end
end
