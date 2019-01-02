use Mix.Config


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :planga, PlangaWeb.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
# config :planga, Planga.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "planga_test",
#   hostname: "localhost",
#   pool: Ecto.Adapters.SQL.Sandbox

config :hound,
  driver: "chrome_driver",
  browser: "chrome_headless",
  app_host: "http://localhost",
  app_port: 4001


config :planga, Planga.Repo,
  adapter: EctoMnesia.Adapter,
  # priv: "priv/ecto_mnesia_repo",
  # host: {:system, :atom, "MNESIA_HOST", Kernel.node()},
  host: node(),
  storage_type: :ram_copies

config :ecto_mnesia,
  host: node(),
  storage_type: :ram_copies

config :mnesia,
  # Make sure this directory exists
  dir: 'test/'
