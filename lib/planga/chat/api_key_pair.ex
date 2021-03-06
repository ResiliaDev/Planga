defmodule Planga.Chat.APIKeyPair do
  @moduledoc """
  This schema describes a single API key pair
  (public ID and private key) that is used for secure communication
  by the application using Planga and the Planga Chat Server.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:public_id, :string, []}
  schema "api_key_pairs" do
    field(:secret_key, :string)
    field(:enabled, :boolean)
    belongs_to(:app, Planga.Chat.App)

    timestamps()
  end

  @doc false
  def changeset(api_key_pair, attrs) do
    api_key_pair
    |> cast(attrs, [:public_id, :secret_key, :app_id, :enabled])
    |> validate_required([:public_id, :secret_key, :app_id, :enabled])
  end

  def from_json(api_key_pair \\ %__MODULE__{}, json) do
    api_key_pair
    |> changeset(%{
      enabled: json["active"],
      public_id: json["public_id"],
      secret_key: json["private_key"],
      app_id: json["app_id"]
    })
  end
end
