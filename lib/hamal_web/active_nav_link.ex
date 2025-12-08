defmodule HamalWeb.ActiveNavLink do
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:active_item, _params, _session, socket) do
    socket = attach_hook(socket, :active_item, :handle_params, &set_active_item/3)
    {:cont, socket}
  end

  defp set_active_item(params, url, socket) do
    active_item =
      case socket.view do
        HamalWeb.Admin.ReservationLive.Index ->
          :reservations
      end

    socket = assign(socket, :active_item, active_item)

    {:cont, socket}
  end
end
