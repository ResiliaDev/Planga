# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :planga,
  ecto_repos: [Planga.Repo]

# Configures the endpoint
config :planga, PlangaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dgTIYvEjoRnW2skBhpjBpxCeR0TqB51dcAl0+CTWfpm9eKAThxdLSv4N2hVxWif7",
  render_errors: [view: PlangaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Planga.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :ecto_mnesia,
  host: {:system, :atom, "MNESIA_HOST", Kernel.node()},
  storage_type: {:system, :atom, "MNESIA_STORAGE_TYPE", :disc_copies}

config :mnesia,
  dir: 'priv/data/mnesia' # Make sure this directory exists

config :snowflakex, machine_id: 42

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
