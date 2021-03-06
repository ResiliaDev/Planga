defmodule Planga.Chat.Message do
  use Ecto.Schema
  # import Ecto.Changeset

  schema "message" do
    belongs_to(:sender, Planga.Chat.User)
    belongs_to(:conversation, Planga.Chat.Conversation)
    belongs_to(:conversation_user, Planga.Chat.ConversationUser)
    field(:content, :string)

    # Public unique reference, so when message is updated (like content filter), it can be re-loaded, overriding old thing in interface.
    field(:uuid, Ecto.UUID)
    field(:deleted_at, :utc_datetime)

    timestamps()
  end

  @doc false
  def new(attrs \\ %{}) do
    %__MODULE__{id: Snowflakex.new!(), uuid: Ecto.UUID.autogenerate()}
    |> Ecto.Changeset.cast(Map.new(attrs), [
      :content,
      :conversation_id,
      :sender_id,
      :conversation_user_id
    ])
    |> Ecto.Changeset.validate_required([
      :id,
      :content,
      :conversation_id,
      :sender_id,
      :conversation_user_id
    ])
    |> Ecto.Changeset.validate_change(:content, fn :content, content ->
      case valid_message?(content) do
        true -> []
        false -> [content: "Invalid Message Content"]
      end
    end)
    |> apply_changes
  end

  defp apply_changes(changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset.errors}
    end
  end

  @doc """
  False if message is invalid and should not be sent.
  """
  def valid_message?(message_content) do
    not empty_message?(message_content) && String.length(message_content) <= 4096
  end

  defp empty_message?(message), do: String.trim(message) == ""

  def hide_message(message = %__MODULE__{}, hidden_time = %DateTime{} \\ DateTime.utc_now()) do
    %__MODULE__{message | deleted_at: hidden_time}
  end

  def show_message(message = %__MODULE__{}) do
    %__MODULE__{message | deleted_at: nil}
  end

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
        # TODO: Too many fields related to author. Should be moved to substructure instead.
        "author_name" => message.sender.name |> html_escape,
        "author_role" => message.conversation_user.role,
        "author_uuid" => "#{message.conversation_user.id}",
        "content" => message.content |> html_escape,
        "sent_at" => message.inserted_at,
        "deleted_at" => message.deleted_at
      }
    end

    defp html_escape(unsafe_string) do
      unsafe_string
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()
    end
  end
end
