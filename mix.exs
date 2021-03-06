defmodule Planga.Mixfile do
  use Mix.Project

  def project do
    [
      app: :planga,
      version: "0.8.9",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Planga.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:plug_cowboy, "~> 1.0"},
      {:gettext, "~> 0.11"},
      # {:sqlite_ecto2, "~> 2.2"},
      {:ecto, "~> 2.1.6", override: true},
      # {:ecto_mnesia, "~> 0.9.0"},
      # {:ecto_mnesia, "~> 0.9.1"},
      # {:ecto_mnesia, git: "git@github.com:Nebo15/ecto_mnesia.git"},
      {:ecto_mnesia, git: "https://github.com/Qqwy/ecto_mnesia.git", branch: "master"},
      {:corsica, "~> 1.0"},
      {:snowflakex, "~> 1.1"},
      {:jose, "~> 1.8.4"},
      {:poison, "~> 3.1"},
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},
      {:httpoison, "~> 1.0"},
      {:exceptional, "~> 2.1"},
      {:tea_vent, git: "https://github.com/Qqwy/elixir-tea_vent.git", branch: "master"},

      # Communication with Ruby:
      {:amqp, "~> 1.0.3"},
      {:rabbit_common, "~> 3.7.8"},
      {:ranch, "~> 1.6.2", override: true},
      {:recon, "2.3.6", override: true},
      {:ranch_proxy_protocol, "~> 2.1", override: true},

      # Releases: 
      {:distillery, "~> 1.5.4", runtime: false},
      # {:planga_phoenix, "~> 1.0.0"},
      {:planga_phoenix, git: "https://github.com/ResiliaDev/planga-phoenix.git"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:observer_cli, "~> 1.3"},

      # Testing
      {:stream_data, "~> 0.1", only: [:dev, :test]},
      {:hound, "~> 1.0", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
      # test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
