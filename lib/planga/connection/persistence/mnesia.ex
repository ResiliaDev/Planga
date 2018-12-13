defmodule Planga.Connection.Persistence.Mnesia do
  @behaviour Planga.Connection.Persistence.Behaviour

  import Ecto.Query, warn: false
  alias Planga.Repo
  alias Planga.Chat.{User, App}

  @doc """
  Given a user's `remote_id`, returns the User struct.
  Will throw an Ecto.NoResultsError error if user could not be found.

  TODO move username to different function
  """
  def fetch_user_by_remote_id!(app_id, remote_user_id, user_name \\ nil) do
    {:ok, user} = Repo.transaction(fn ->
      case Repo.get_by(User, [app_id: app_id, remote_id: remote_user_id]) do
        nil ->
          Repo.insert!(%User{app_id: app_id, remote_id: remote_user_id, name: user_name})
        user -> user
      end
    end)
    user
  end

  def update_username(user_id, remote_user_name) do
    Repo.transaction(fn ->
      User
      |> Repo.get!(user_id)
      |> Ecto.Changeset.change(name: remote_user_name)
      |> Repo.update()
    end)
    :ok
  end

  def fetch_api_key_pair_by_public_id!(pub_api_id) do
    Planga.Repo.get_by!(Planga.Chat.APIKeyPair, public_id: pub_api_id, enabled: true)
  end
end
