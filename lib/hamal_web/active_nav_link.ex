defmodule HamalWeb.ActiveNavLink do
  @moduledoc """
  Handles setting current active menu link as assign in liveview.
  Useful when we need to mark the current page users is having interaction with.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:active_item, _params, _session, socket) do
    socket = attach_hook(socket, :active_item, :handle_params, &set_active_item/3)
    {:cont, socket}
  end

  defp set_active_item(_params, _url, socket) do
    active_item =
      case socket.view do
        HamalWeb.Admin.ReservationLive.Index ->
          :reservations

        HamalWeb.Admin.GuestLive.Index ->
          :guests

        HamalWeb.Admin.StaysLive.Index ->
          :stays

        _ ->
          nil
      end

    {:cont, assign(socket, :active_item, active_item)}
  end
end
