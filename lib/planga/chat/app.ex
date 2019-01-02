defmodule Planga.Chat.App do
  @moduledoc """
  This schema describes an application that uses Planga:
  An app contains zero or more API key pairs to identify with,
  but all of these connect to the same application.
  """
  use Ecto.Schema
  # import Ecto.Changeset

  schema "apps" do
    field(:name, :string)
    has_many(:api_key_pairs, Planga.Chat.APIKeyPair)

    has_many(:conversations, Planga.Chat.Conversation)
    has_many(:users, Planga.Chat.User)

    timestamps()
  end

  def new(attrs) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(Map.new(attrs), [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> apply_changes
  end

  defp apply_changes(changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset.errors}
    end
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> Ecto.Changeset.cast(attrs, [:name])
    |> Ecto.Changeset.validate_required([:name])
  end

  @deprecated "use from_hash instead?"
  def from_json(app \\ %__MODULE__{}, json) do
    app
    |> changeset(%{name: to_string(json["public_id"])})
  end

  def from_hash(app \\ %__MODULE__{}, hash) do
    app
    |> changeset(%{
      id: hash["id"],
      name: to_string(hash["name"])
    })
  end
end
