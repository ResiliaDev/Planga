defmodule Planga.AppSettingsListener do
  @moduledoc """
  Listens to RabbitMQ for changes in an App's settings
  (and its related API key pairs),
  """
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchange_name "planga_app_settings_updates"

  def init(_opts) do
    send(self(), :setup)
    {:ok, nil}
  end

  defp rabbitmq_connect do
    case AMQP.Connection.open(config()) do
      {:ok, conn} ->
        # Be notified when the connection to RabbitMQ goes down
        Process.monitor(conn.pid)

        {:ok, channel} = setup_channel(conn)
        Logger.info("RabbitMQ connection with Ruby app established!")
        {:ok, channel}

      {:error, reason} ->
        # Reconnection loop
        Logger.warn("RabbitMQ connection to Ruby app failure... reconnecting in ten seconds!")
        Logger.warn("Reason: #{inspect(reason)}")
        :timer.sleep(5_000)
        rabbitmq_connect()
    end
  end

  defp setup_channel(connection) do
    {:ok, channel} = AMQP.Channel.open(connection)
    setup_queue(channel)
    AMQP.Basic.qos(channel, prefetch_count: 10)
    {:ok, channel}
  end

  defp config do
    Application.fetch_env!(:planga, :amqp_settings)
  end

  def handle_info(:setup, _) do
    {:ok, channel} = rabbitmq_connect()
    {:noreply, channel}
  end

  # Reconnect on RabbitMQ failure:
  def handle_info({:DOWN, _, :process, _pid, reason}, _) do
    Logger.warn("RabbitMQ connection to Ruby app just went down! Reason:")
    Logger.warn(inspect(reason))
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
    {:stop, :normal, channel}
  end

  def handle_info(
        {:basic_deliver, payload_binary, %{delivery_tag: _tag, redelivered: _redelivered}},
        channel
      ) do
    payload = :erlang.binary_to_term(payload_binary, [:safe])

    Task.start(fn ->
      Logger.debug(fn -> "Received message: #{inspect(payload)}" end)

      update_rails_app(payload)

      Logger.debug(fn -> "Done updating app!" end)
      Logger.debug(fn -> "------------------" end)
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

  # Updates the local Planga.Chat.App using the remote data
  # from Rails to properly configure it.
  defp update_rails_app(app_map) do
    Planga.Repo.transaction(fn ->
      app_log_name = "#{app_map["id"]}/`#{app_map["name"]}`"

      app =
        case Planga.Repo.get_by(Planga.Chat.App, id: app_map["id"]) do
          nil ->
            Logger.info("Creating new app #{app_log_name}")
            %Planga.Chat.App{}

          existing ->
            Logger.info("Updating existing app #{app_log_name}")
            existing
        end

      app =
        app
        |> Planga.Chat.App.from_hash(app_map)
        |> Planga.Repo.insert_or_update!()

      app_map["api_credentials"]
      |> Enum.each(&update_credential2(&1, app))

      Logger.info("Done updating #{app_log_name}")

      :ok
    end)
  end

  defp update_credential2(api_key_map, app) do
    Planga.Repo.transaction(fn ->
      api_key_pair =
        case Planga.Repo.get(Planga.Chat.APIKeyPair, api_key_map["public_id"]) do
          nil ->
            Logger.info("Creating new key #{api_key_map["public_id"]}")
            %Planga.Chat.APIKeyPair{public_id: api_key_map["public_id"]}

          existing ->
            Logger.info("Updating existing key #{api_key_map["public_id"]}")
            existing
        end

      api_key_map = Map.merge(api_key_map, %{"app_id" => app.id})

      api_key_pair
      |> Planga.Chat.APIKeyPair.from_json(api_key_map)
      |> Planga.Repo.insert_or_update!()

      Logger.info("Done with key #{api_key_map["public_id"]}!")
    end)
  end
end
