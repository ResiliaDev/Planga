defmodule Planga.AppSettingsListener do
  @moduledoc """
  Listens to RabbitMQ for changes in an App's settings
  (and its related API key pairs),
  """
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchange_name "planga_app_settings_updates"

  def init(_opts) do
    {:ok, conn} = AMQP.Connection.open() # TODO Configure
    {:ok, channel} = AMQP.Channel.open(conn)

    setup_queue(channel)
    # :ok = Basic.qos(channel, prefetch_count: 10)
    {:ok, channel}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
    {:stop, :normal, channel}
  end

  def handle_info({:basic_deliver, payload_binary, %{delivery_tag: tag, redelivered: redelivered}}, channel) do
    payload = :erlang.binary_to_term(payload_binary)
    Task.start(fn ->
      # TODO Actual handling logic here
      IO.puts "Received message: #{inspect(payload)}"
    end)
    {:noreply, channel}
  end

  defp setup_queue(channel) do
    AMQP.Exchange.declare(channel, @exchange_name, :fanout)
    {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
    # :ok = Exchange.fanout(channel, @exchange, durable: true)
    :ok = AMQP.Queue.bind(channel, queue_name, @exchange_name)
    {:ok, _consumer_tag} = AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)
  end
end
