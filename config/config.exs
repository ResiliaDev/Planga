# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :planga, environment: :"#{Mix.env()}"

# General application configuration
config :planga,
  ecto_repos: [Planga.Repo],
  planga_dashboard_url: "http://0.0.0.0:3000",
  planga_api_key_sync_password: "4eHjPZYTw7Wex455xsM5KQ"

config :planga, Planga.Repo,
  adapter: EctoMnesia.Adapter,
  # priv: "priv/ecto_mnesia_repo",
  # host: {:system, :atom, "MNESIA_HOST", Kernel.node()},
  host: :"planga@127.0.0.1",
  storage_type: :disc_copies

config :ecto_mnesia,
  host: :"planga@127.0.0.1",
  storage_type: :disc_copies

config :mnesia,
  # Make sure this directory exists
  dir: 'priv/'

config :planga, Planga.Scheduler,
  jobs: [
    # Every minute, resync API keys
    # {"* * * * *",      {Planga.Tasks.ApiKeySync, :sync_all, []}},
    # Every hour, create normal backup
    {"@daily", {Planga.Tasks.MnesiaBackup, :backup_everything, []}},
    # At midnight, create plaintext backup
    {"@weekly", {Planga.Tasks.MnesiaBackup, :backup_readable, []}}
  ]

# Configures the endpoint
config :planga, PlangaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dgTIYvEjoRnW2skBhpjBpxCeR0TqB51dcAl0+CTWfpm9eKAThxdLSv4N2hVxWif7",
  render_errors: [view: PlangaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Planga.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id],
  level: :debug

config :snowflakex, machine_id: 42

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
