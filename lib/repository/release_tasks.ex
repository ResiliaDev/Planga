defmodule Repository.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :ecto_mnesia,
    :ecto
  ]

  # def repository, do: :repository

  # def repos, do: Application.get_env(repository(), :ecto_repos, [])
  def repos, do: [Planga.Repo]

  def migrate do
    migration()
  end

  def migration() do
    IO.puts("==> Migrate all the repos")
    IO.inspect(repos())
    Enum.each(repos(), &run_migrations_for/1)
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(repo) do
    IO.puts("==> Run migration")

    config = [
      host: Application.get_env(:ecto_mnesia, :host),
      storage_type: Application.get_env(:ecto_mnesia, :storage_type)
    ]

    Repository.__adapter__().storage_up(config)

    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  end

  def migrations_path(repo), do: priv_path_for(repo, "migrations")

  def priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
