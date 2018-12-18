defmodule Planga.Repo do
  use Ecto.Repo, otp_app: :planga
  # adapter: Sqlite.Ecto2
  # adapter: EctoMnesia.Adapter

  # @doc """
  # Dynamically loads the repository url from the
  # DATABASE_URL environment variable.
  # """
  # def init(_, opts) do
  #   {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  # end

  def fetch(queryable, id) do
    case __MODULE__.get(queryable, id) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  def fetch_by(queryable, keys) do
    case __MODULE__.get_by(queryable, keys) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end
end
