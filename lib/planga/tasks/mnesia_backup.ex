defmodule Planga.Tasks.MnesiaBackup do
  @moduledoc """
  This module defines a task to backup the complete Mnesia database of Planga.
  This is to be run every so often to make sure we can re-establish a snapshot of the chat,
  in the unlikely event that the system breaks down completely.

  As the famous Islamic proverb:
  > "Trust in Allah, but do tie your camel".
  """
  require Logger

  @doc """
  Performs a normal Mnesia backup.

  (See: http://erlang.org/doc/man/mnesia.html#backup-1)
  """
  def backup_everything do
    Logger.info("Creating normal Mnesia backup...")

    res =
      "normal"
      |> backup_name()
      |> String.to_charlist()
      |> :mnesia.backup()

    Logger.info("Done with normal Mnesia backup. Result code: `#{res}`")
  end

  defp backup_name(backup_type) do
    now = DateTime.utc_now()
    backup_name = "planga-#{DateTime.to_iso8601(now)}-#{backup_type}.mnesia.backup"
    backup_folder = "priv/repo/backups/"
    backup_folder <> backup_name
  end

  @doc """
  Backups the database in a readable format.

  This is mostly here for easy introspection purposes.
  Once Planga starts growing and becomes more stable, it should _definitely_ be removed,
  because it creates large files and is not meant for distributed environments.

  (c.f. http://erlang.org/doc/man/mnesia.html#dump_to_textfile-1 )
  """
  def backup_readable do
    Logger.info("Creating readable Mnesia backup...")

    res =
      "readable_text"
      |> backup_name()
      |> String.to_charlist()
      |> :mnesia.dump_to_textfile()

    Logger.info("Done with readable Mnesia backup. Result code: `#{res}`")
  end
end
