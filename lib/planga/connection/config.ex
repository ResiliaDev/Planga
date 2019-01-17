defmodule Planga.Connection.Config do
  @moduledoc """
  This module handles the decryption and parsing of the Encrypted Configuration that is sent
  when someone attempts to make a connection to the Planga Chatserver.
  """

  # @enforce_keys [:conversation_id, :current_user_id, :current_user_name]
  defstruct [
    :conversation_id,
    :current_user_id,
    :current_user_name,
    other_users: [],
    current_user_role: nil
  ]

  defmodule OtherUserInfo do
    @moduledoc """
    Each entry in the 'other_users' field
    """
    defstruct [:id, :name]

    def from_json_hash(json_hash) do
      types = %{id: :any, name: :any}

      changeset =
        {%__MODULE__{}, types}
        |> Ecto.Changeset.cast(json_hash, Map.keys(types))
        |> Ecto.Changeset.validate_required(json_hash, Map.keys(types))

      if changeset.valid? do
        result =
          changeset
          |> Ecto.Changeset.apply_changes()
          |> Map.update!(:id, &to_string/1)

        {:ok, result}
      else
        {:error, inspect(changeset.errors)}
      end
    end

    def from_list(other_users_json_list) do
      other_users_json_list
      |> reduce_errors(&from_json_hash/1)
    end

    defp reduce_errors(enumerable, function) do
      enumerable
      |> Enum.reduce({:ok, []}, fn
        {:error, error}, _ ->
          {:error, error}

        {:ok, list}, elem ->
          case function.(elem) do
            {:ok, elem} -> [elem | list]
            {:error, error} -> {:error, error}
          end
      end)
    end
  end

  @doc """
  Transforms the JSON from the client into a Config struct.
  Returns an {:error, string} if its syntax is not correct.
  """
  def from_json_hash(json_hash) do
    types = %{
      conversation_id: :any,
      current_user_id: :any,
      current_user_name: :string,
      other_users: :any,
      current_user_role: :string
    }

    changeset =
      {%__MODULE__{}, types}
      |> Ecto.Changeset.cast(json_hash, Map.keys(types))
      |> Ecto.Changeset.validate_required(Map.keys(types) -- [:other_users, :current_user_role])

    if changeset.valid? do
      result =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> Map.update!(:conversation_id, &to_string/1)
        |> Map.update!(:current_user_id, &to_string/1)

      with {:ok, other_users} = __MODULE__.OtherUserInfo.from_list(result.other_users) do
        result = Map.put(result, :other_users, other_users)
        {:ok, result}
      end

      {:ok, result}
    else
      {:error, inspect(changeset.errors)}
    end
  end

  @doc """

  Decryps a configuration that has been encrypted using the JOSE-JWK format,
  to a hash with string keys.
  """
  def decrypt(encrypted_info, api_key_pair) do
    with {:ok, json_hash} <- Planga.Crypto.JOSE.decrypt(encrypted_info, api_key_pair.secret_key),
         {:ok, config} <- from_json_hash(json_hash) do
      {:ok, config}
    end
  end

  @doc """
  Returns a hash containing the information
  that, if the secret_info was correct,
  is now public information to be returned and used in the browser on connection success.

  TODO doctests
  """
  def public_info(secret_info) do
    %{"current_user_name" => secret_info.current_user_name}
  end
end
