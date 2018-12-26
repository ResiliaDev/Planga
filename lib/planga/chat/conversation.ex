defmodule Planga.Chat.Conversation do
  @moduledoc """
  This schema describes a single chat-conversation
  between one or more users.
  """
  use Ecto.Schema
  # import Ecto.Changeset

  schema "conversations" do
    field(:remote_id, :string)
    belongs_to(:app, Planga.Chat.App)
    many_to_many(:users, Planga.Chat.User, join_through: "conversations_users")

    timestamps()
  end

  def new(attrs) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(Map.new(attrs))
    |> Ecto.Changeset.cast(attrs, [:remote_id])
    |> Ecto.Changeset.validate_required([:remote_id])
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
  def changeset(conversation, attrs) do
    conversation
    |> Ecto.Changeset.cast(attrs, [:remote_id])
    |> Ecto.Changeset.validate_required([:remote_id])
  end
end
