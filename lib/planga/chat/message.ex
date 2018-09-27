defmodule Planga.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset


  schema "message" do
    belongs_to :sender, Planga.Chat.User
    belongs_to :conversation, Planga.Chat.Conversation
    field :content, :string
    field :uuid, Ecto.UUID # Public unique reference, so when message is updated (like content filter), it can be re-loaded, overriding old thing in interface.

    timestamps()
  end

  @doc false
  def changeset(message, attrs \\ %{}) do
    message
    |> change(uuid: (message.uuid || Ecto.UUID.autogenerate)) # Not auto-handled by Ecto.Mnesia
    |> cast(attrs, [:sender_id, :content])
    |> validate_required([:sender_id, :content, :uuid, :conversation_id])
    |> validate_length(:content, max: 4096) # To prevent abuse
  end

  @doc """
  False if message is invalid and should not be sent.
  """
  def valid_message?(message) do
    not empty_message?(message)
  end

  defp empty_message?(message), do: String.trim(message) == ""
end
