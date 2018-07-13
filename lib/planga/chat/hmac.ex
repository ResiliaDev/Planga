defmodule Planga.Chat.HMAC do

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, Message, Conversation, App, ConversationUser}


  @doc """
  Makes sure a chatter has a correct SHA256-HMAC indicating their App ID.
  """
  def check_user(app_id, remote_user_id, base64_hmac), do: check(app_id, remote_user_id, base64_hmac)

  @doc """
  Alters the user's set name iff they have a correct SHA256-HMAC specifying their new name.
  """
  def update_user_name_if_hmac_correct(app_id, user_id, remote_user_name_hmac, remote_user_name) do
    if check(app_id, remote_user_name, remote_user_name_hmac) do
      Repo.transaction(fn ->
        Repo.get!(User, user_id)
        |> Ecto.Changeset.change(name: remote_user_name)
        |> Repo.update()
      end)
    end
    {:error, :invalid_hmac}
  end

  @doc """
  Makes sure a chatter uses a correct SHA256-HMAC for their username.
  """
  def check_user_name(app_id, user_name, base64_hmac), do: check(app_id, user_name, base64_hmac)

  @doc """
  Makes sure a chatter conversation has a correct SHA256-HMAC.
  """
  def check_conversation(app_id, conversation_id, base64_hmac), do: check(app_id, conversation_id, base64_hmac)

  defp check(app_id, value, hmac) do
    app = Repo.get!(App, app_id)
    local_computed_hmac = :crypto.hmac(:sha256, app.secret_api_key, value)

    local_computed_hmac == Base.decode64!(hmac)
  end
end
