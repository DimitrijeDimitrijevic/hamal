defmodule HamalWeb.Admin.GuestLive.Index do
  use HamalWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    {:ok, assign(socket, msg: "hello")}
  end

  # Handles mostly live actions
  # Unsigned params are the params that are coming trought url
  @impl true
  def handle_params(unsigned_params, uri, socket) do
    IO.inspect(unsigned_params: unsigned_params)
    IO.inspect(uri: uri)
    live_action = socket.assigns.live_action
    guest_id = Map.get(unsigned_params, "id")

    socket =
      socket
      |> assign(guest_id: guest_id, live_action: live_action)

    {:noreply, socket}
  end
end
