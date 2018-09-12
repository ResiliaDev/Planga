defmodule Planga.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset


  schema "message" do
    belongs_to :sender, Planga.Chat.User
    belongs_to :conversation, Planga.Chat.Conversation
    field :content, :string
    field :uuid, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(message, attrs \\ %{}) do
    message
    |> change(uuid: (message.uuid || Ecto.UUID.autogenerate)) # Not auto-handled by Ecto.Mnesia
    |> cast(attrs, [:sender_id, :content])
    |> validate_required([:sender_id, :content, :uuid, :conversation_id])
  end

  @doc """
  False if message is invalid and should not be sent.
  """
  def valid_message?(message) do
    not empty_message?(message)
  end

  defp empty_message?(message), do: String.trim(message) == ""
end
