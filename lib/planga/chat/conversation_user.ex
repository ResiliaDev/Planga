defmodule Planga.Chat.ConversationUser do
  @moduledoc """
  This schema is the relation between a user
  and a given conversation.
  """
  use Ecto.Schema
  # import Ecto.Changeset

  schema "conversations_users" do
    # field(:conversation_id, :integer)
    belongs_to(:conversation, Planga.Chat.Conversation)
    # field(:user_id, :integer)
    belongs_to(:user, Planga.Chat.User)
    field(:role, :string, default: "")
    field(:banned_until, :utc_datetime)

    timestamps()
  end

  def new(attrs) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(Map.new(attrs), [:conversation_id, :user_id, :role, :banned_until])
    |> Ecto.Changeset.validate_required([:conversation_id, :user_id])
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
  def changeset(conversation_user, attrs) do
    conversation_user
    |> Ecto.Changeset.cast(attrs, [:conversation_id, :user_id])
    |> Ecto.Changeset.validate_required([:conversation_id, :user_id])
  end

  def ban(
        conversation_user = %__MODULE__{},
        duration_minutes,
        ban_start_time = %DateTime{} \\ DateTime.utc_now()
      )
      when is_integer(duration_minutes) and duration_minutes > 0 do
    require Logger

    now = DateTime.utc_now()
    ban_end = Timex.add(now, Timex.Duration.from_minutes(duration_minutes))

    case bannable?(conversation_user) do
      false ->
        Logger.warn("Someone attempted to ban unbannable user #{inspect(conversation_user)}")

        conversation_user

      true ->
        %__MODULE__{conversation_user | banned_until: ban_end}
    end
  end

  def bannable?(conversation_user = %__MODULE__{}) do
    # conversation_user.role == nil
        true
  end

  def banned?(conversation_user, current_datetime \\ DateTime.utc_now())
  def banned?(conversation_user = %__MODULE__{banned_until: nil}, current_datetime), do: false

  def banned?(
        conversation_user = %__MODULE__{banned_until: banned_until = %DateTime{}},
        current_datetime
      ) do
    DateTime.compare(current_datetime, banned_until) == :lt
  end

  def unban(conversation_user = %__MODULE__{}) do
    %__MODULE__{conversation_user | banned_until: nil}
  end

  def set_role(conversation_user = %__MODULE__{}, role) when role in [nil, "moderator"] do
    conversation_user
    |> Ecto.Changeset.change(role: role)
  end

  def is_moderator?(conversation_user = %__MODULE__{}) do
    conversation_user.role == "moderator"
  end

  defmodule Presentation do
    def conversation_user_dict(conversation_user) do
      %{
        "user_id" => conversation_user.user_id,
        "role" => conversation_user.role,
        "banned_until" =>
          case conversation_user.banned_until do
            nil -> nil
            datetime -> DateTime.to_unix(datetime)
          end
      }
    end
  end
end
