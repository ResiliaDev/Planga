defmodule Planga.Chat.User do
  @moduledoc """
  This module describes the schema of a single Chat-user
  (So someone that interacts with the chat interface)
  """
  use Ecto.Schema
  # import Ecto.Changeset

  schema "users" do
    belongs_to(:app, Planga.Chat.App)
    field(:name, :string)
    field(:remote_id, :string)

    has_many(:sent_messages, Planga.Chat.Message)
    many_to_many(:conversations, Planga.Chat.Conversation, join_through: "conversations_users")

    timestamps()
  end

  def new(attrs) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(Map.new(attrs), [:app_id, :remote_id])
    |> Ecto.Changeset.validate_required([:app_id, :remote_id])
    |> apply_changes()
  end

  defp apply_changes(changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset.errors}
    end
  end

  # @doc false
  # def changeset(user, attrs) do
  #   user
  #   |> cast(attrs, [:name, :remote_id])
  #   |> validate_required([:name, :remote_id])
  # end
end
