defmodule Planga.Application do
  @moduledoc """
  The Planga Chat Application.

  Root of the Planga OTP App supervision tree.
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(Planga.Repo, []),
        # Start the endpoint when the application starts
        supervisor(PlangaWeb.Endpoint, []),
        # Start your own worker by calling: Planga.Worker.start_link(arg1, arg2, arg3)
        # worker(Planga.Worker, [arg1, arg2, arg3]),
        worker(Planga.Scheduler, [])
      ] ++ env_specific_apps()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Planga.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PlangaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def env_specific_apps do
    import Supervisor.Spec

    if Application.get_env(:planga, :environment) == :test do
      []
    else
      # Connects to RabbitMQ and manages changes in app settings.
      [worker(Planga.AppSettingsListener, [])]
    end
  end
end
