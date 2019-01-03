defmodule PlangaWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  # channel "room:*", PlangaWeb.RoomChannel

  channel("encrypted_chat:*", PlangaWeb.ChatChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket, connect_info) do
    case params do
      %{"config" => connection_config, "public_api_id" => public_api_id} ->
        with {:ok, %{socket_assigns: socket_assigns}} <-
               Planga.Connection.connect(public_api_id, connection_config),
             socket = fill_socket(socket, socket_assigns) do
          {:ok, socket}
        else
          # NOTE This is a prime location to log in a way visible to the App Developer.
          {:error, reason} ->
            :error

          other ->
            :error
        end

      other ->
        :error
    end
  end

  defp fill_socket(socket, socket_assigns) do
    socket_assigns
    |> Enum.reduce(socket, fn {key, value}, socket -> assign(socket, key, value) end)
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PlangaWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
