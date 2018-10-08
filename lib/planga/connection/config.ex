defmodule Planga.Connection.Config do
  @moduledoc """
  This module handles the decryption and parsing of the Encrypted Configuration that is sent
  when someone attempts to make a connection to the Planga Chatserver.
  """

  # @enforce_keys [:conversation_id, :current_user_id, :current_user_name]
  defstruct [:conversation_id, :current_user_id, :current_user_name, other_users: []]

  defmodule OtherUserInfo do
    @moduledoc """
    Each entry in the 'other_users' field
    """
    defstruct [:id, :name]

    def from_json_hash(json_hash) do
      types = %{id: :any, id: :any}
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
        {:error, error}, _ -> {:error, error}
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
    types = %{conversation_id: :any, current_user_id: :any, current_user_name: :string, other_users: :any}
    changeset =
      {%__MODULE__{}, types}
      |> Ecto.Changeset.cast(json_hash, Map.keys(types))
      |> Ecto.Changeset.validate_required(Map.keys(types) -- [:other_users])

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

  defp field_to_string(struct, fieldname) do
    %{struct | fieldname => to_string(struct.fieldname)}
  end

  @doc """

  Decryps a configuration that has been encrypted using the JOSE-JWK format,
  to a hash with string keys.
  """
  def decrypt(encrypted_info, api_key_pair) do
    with {:ok, json_hash} <- jose_decrypt(encrypted_info, api_key_pair.secret_key),
         {:ok, config} <- from_json_hash(json_hash) do
      {:ok, config}
    end
  end

  defp ensure_is_binary(val) when is_binary(val), do: val
  defp ensure_is_binary(val) when not is_binary(val), do: to_string(val)

  @doc """
  Returns a hash containing the information
  that, if the secret_info was correct,
  is now public information to be returned and used in the browser on connection success.

  TODO doctests
  """
  def public_info(secret_info) do
    %{"current_user_name" => secret_info.current_user_name}
  end

  @doc """
  Reads and parses the 'other_users' field of the secret_info.
  Falls back to the default (an empty list).

  TODO doctests
  """
  def read_other_users(encrypted_info) do
    encrypted_info.other_users |> parse_other_users()
  end

  defp parse_other_users(other_users) do
    other_users
    |> Enum.map(fn
      user ->
      if Map.has_key?(user, "id") do
        user_map = %{id: user["id"], name: user["name"]}
        {:ok, user_map}
      else
        {:error, "invalid `other_users` element: missing `id` field."}
      end
    end)
    |> Enum.map(&elem(&1, 1))
  end


  defp jose_decrypt(encrypted_conversation_info, secret_key) do

    # res
    # |> elem(0)
    # |> Poison.decode!()
    # |> from_json_hash
    # |> IO.inspect(label: "TODO: conversion into module")
    with {:ok, {json_str, _jwk_decryption_details}} = do_jose_decrypt(encrypted_conversation_info, secret_key),
         {:ok, json_hash} <- Poison.decode(json_str) do
      {:ok, json_hash}
    else
      {:error, :invalid, _} ->
        {:error, "Could not parse JSON in encrypted configuration."}
      {:error, error} ->
        {:error, "Invalid Planga configuration: #{to_string(error)}"}
    end


    # res =
    #   |> IO.inspect(label: "The decrypted strigifiedJSON Planga will deserialize: ")
    #   |> Poison.decode()
    #   |> from_json_hash
    #   |> IO.inspect(label: "TODO: conversion into module")
    # case res do
    #   {:ok, res} -> {:ok, res}
    #   _ -> {:error, "Could not parse JSON in encrypted configuration."}
    # end
  end

  defp do_jose_decrypt(encrypted_conversation_info, encoded_secret_key) do
    with {:ok, secret_key} <- do_jose_decode_api_key(encoded_secret_key) do
      try do
        res = JOSE.JWE.block_decrypt(secret_key, encrypted_conversation_info)
        {:ok, res}
      rescue
        FunctionClauseError -> {:error, "Cannot decrypt `encrypted_conversation_info`. Either the provided public key does not match the used secret key, or the ciphertext is malformed."}
      end
    end
  end

  defp do_jose_decode_api_key(encoded_secret_key) do
    try do
      secret_key = JOSE.JWK.from_map(%{"k" => encoded_secret_key, "kty" => "oct"})
      {:ok, secret_key}
    rescue
      FunctionClauseError -> {:error, "invalid secret API key format!"}
    end
  end
end
