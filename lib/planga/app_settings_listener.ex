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
        Logger.info "RabbitMQ connection with Ruby app established!"
        {:ok, channel}

      {:error, reason} ->
        # Reconnection loop
        Logger.warn "RabbitMQ connection to Ruby app failure... reconnecting in ten seconds!"
        Logger.warn "Reason: #{inspect(reason)}"
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
    Logger.warn "RabbitMQ connection to Ruby app just went down! Reason:"
    Logger.warn inspect(reason)
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
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
      IO.puts "Received message: #{inspect(payload)}"
      update_rails_user(payload)
      IO.puts "Done updating user!"
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

  @doc """
  Currently, the Rails system works with 'users', so this is how we are managing individual applications,
  using the user ID as app name.
  """
  defp update_rails_user(user_map) do
    Planga.Repo.transaction(fn ->
      user_map["api_credentials"]
      |> Enum.each(&update_credential/1)
    end)
  end

  defp update_credential(api_key_map) do
    Planga.Repo.transaction(fn ->

      app =
        case Planga.Repo.get_by(Planga.Chat.App, name: to_string(api_key_map["public_id"])) do
          nil ->
            Logger.info("Creating new app #{api_key_map["public_id"]}")
            %Planga.Chat.App{name: api_key_map["public_id"]}
          existing ->
            Logger.info("Updating existing app #{api_key_map["public_id"]}")
            existing
        end

      app =
        app
        |> Planga.Chat.App.from_json(api_key_map)
        |> Planga.Repo.insert_or_update!


      api_key_pair =
        case Planga.Repo.get(Planga.Chat.APIKeyPair, api_key_map["public_id"]) do
          nil ->
            Logger.info("Creating new key #{api_key_map["public_id"]}")
            %Planga.Chat.APIKeyPair{public_id: api_key_map["public_id"]}
          existing ->
            Logger.info("Updating existing key #{api_key_map["public_id"]}")
            existing
      end

      api_key_map =
        Map.merge(api_key_map, %{"app_id" => app.id})

      api_key_pair
      |> Planga.Chat.APIKeyPair.from_json(api_key_map)
      |> Planga.Repo.insert_or_update!
      Logger.info("Done with key #{api_key_map["public_id"]}!")
    end)
  end

end
