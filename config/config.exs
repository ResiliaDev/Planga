# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :plange,
  ecto_repos: [Plange.Repo]

# Configures the endpoint
config :plange, PlangeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dgTIYvEjoRnW2skBhpjBpxCeR0TqB51dcAl0+CTWfpm9eKAThxdLSv4N2hVxWif7",
  render_errors: [view: PlangeWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Plange.PubSub,
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



# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
