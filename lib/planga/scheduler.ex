defmodule Planga.Scheduler do
  @moduledoc """
  The Planga.Scheduler uses Quantum
  to schedule tasks that are supposed to happen in a fixed interval,
  a lá CRON (but self-contained).
  """
  use Quantum.Scheduler,
  otp_app: :planga
end
