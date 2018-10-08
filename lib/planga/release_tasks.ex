defmodule Planga.ReleaseTasks do
  @moduledoc """
  This module is an effort to manage migrations on top of mnesia_ecto.

  Hint: It does not work very nice, and we currently do not know why.

  The only way migrations seem to work in production,
  is by running `Planga.ReleaseTasks.migrate` from within
  the running application.

  More info: https://github.com/Nebo15/ecto_mnesia/issues/56
  """
  require Logger
  @start_apps [
    :crypto,
    :ssl,
    :mnesia,
    :ecto_mnesia,
    :ecto,
    :logger
  ]

  # def repository, do: :repository

  # def repos, do: Application.get_env(repository(), :ecto_repos, [])
  def repos, do: [Planga.Repo]

  def migrate do
    Application.load(:planga)
    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    try do
      Logger.info "Mnesia status:"
      Logger.info inspect(:mnesia.system_info())
      migration()
    rescue
      error ->
        Logger.warn inspect(error)
        Logger.warn inspect(System.stacktrace)
    end
  end

  def migration() do
    Logger.info("==> Migrate all the repos")
    Logger.info(repos())
    Enum.each(repos(), &run_migrations_for/1)
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(repo) do
    Logger.info("==> Run migration")

    config = [
      host: Application.get_env(:ecto_mnesia, :host),
      storage_type: Application.get_env(:ecto_mnesia, :storage_type)
    ]

    case repo.__adapter__().storage_up(config) do

      :ok -> Logger.info("Success creating DB")
      {:error, :already_up} -> Logger.info("DB was already created before.")
      {:error, unknown_error} -> Logger.error("Unknown error: #{inspect unknown_error}")
    end

    app = Keyword.get(repo.config, :otp_app)
    Logger.info("Running migrations for #{app}")
    Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  end

  def migrations_path(repo), do: priv_path_for(repo, "migrations")

  def priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
