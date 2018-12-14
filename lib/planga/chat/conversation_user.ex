defmodule Planga.Chat.ConversationUser do
  @moduledoc """
  This schema is the relation between a user
  and a given conversation.
  """
  use Ecto.Schema
  import Ecto.Changeset


  schema "conversations_users" do
    field :conversation_id, :integer
    field :user_id, :integer
    field :role, :string, default: ""
    field :banned_until, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(conversation_user, attrs) do
    conversation_user
    |> cast(attrs, [:conversation_id, :user_id])
    |> validate_required([:conversation_id, :user_id])
  end

  def ban(conversation_user = %__MODULE__{}, duration_minutes, ban_start_time = %DateTime{} \\ DateTime.utc_now) when is_integer(duration_minutes) and duration_minutes > 0 do
    now = DateTime.utc_now
    ban_end = Timex.add(now, Timex.Duration.from_minutes(duration_minutes))

    case bannable?(conversation_user) do
      false ->
        # TODO log this?
        conversation_user
      true ->
        conversation_user
        |> change(banned_until: ban_end)
    end
  end

  defp bannable?(conversation_user = %__MODULE__{}) do
    conversation_user.role == nil
  end

  def unban(conversation_user = %__MODULE__{}) do
    conversation_user
    |> change(banned_until: nil)
  end

  def set_role(conversation_user = %__MODULE__{}, role) when role in [nil, "moderator"] do
    conversation_user
    |> change(role: role)
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
