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
    |> validate_change(:content, fn :content, message -> valid_message?(message.content) end)
  end

  @doc """
  False if message is invalid and should not be sent.
  """
  def valid_message?(message_content) do
    not empty_message?(message_content) && String.length(message_content) <= 4096
  end

  defp empty_message?(message), do: String.trim(message) == ""
end
