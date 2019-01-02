defmodule Planga.Scheduler do
  use Quantum.Scheduler, otp_app: :planga
  @moduledoc """
  The Planga.Scheduler uses Quantum
  to schedule tasks that are supposed to happen in a fixed interval,
  a lá CRON (but self-contained).
  """
end
