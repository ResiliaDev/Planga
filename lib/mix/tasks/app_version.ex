defmodule Mix.Tasks.AppVersion do
  @moduledoc """
  This is used to fetch the current application version set in `mix.exs`
  from the command-line.

  Useful for build scripts.
  """
  use Mix.Task

  # Only accessible during compile time
  @version Mix.Project.config[:version]

  def run(_args) do
    IO.puts(@version)
  end
end
