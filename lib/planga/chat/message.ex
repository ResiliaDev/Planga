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


  defmodule Presentation do
    @moduledoc """
    Showing Messages to the outside world.
    TODO Move to other location?
    """
    @doc """
    Turns returned message information into a format
    that only contains the info the outside world is allowed to see.
    """
    def message_dict(message) do
      %{
        "uuid" => message.uuid,
        "name" => message.sender.name |> html_escape,
        "content" => message.content |> html_escape,
        "sent_at" => message.inserted_at
      }
    end

    defp html_escape(unsafe_string) do
      unsafe_string
      |> Phoenix.HTML.html_escape
      |> Phoenix.HTML.safe_to_string
    end
  end
end
