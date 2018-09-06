defmodule Mix.Tasks.AppVersion do
  use Mix.Task

  # Only accessible during compile time
  @version Mix.Project.config[:version]

  def run(_args) do
    IO.puts(@version)
  end
end
