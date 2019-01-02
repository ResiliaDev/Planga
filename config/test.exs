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
config :planga, Planga.Repo,
  adapter: EctoMnesia.Adapter,
  host: :"planga-test@127.0.0.1",
  storage_type: :ram_copies # No need to persist data in-between test runs

config :ecto_mnesia,
  host: :"planga-test@127.0.0.1",
  storage_type: :ram_copies # No need to persist data in-between test runs

config :hound, driver: "chrome_driver", browser: "chrome_headless", app_host: "http://localhost", app_port: 4001
