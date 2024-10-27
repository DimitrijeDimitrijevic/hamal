defmodule HamalWeb.Admin.ReservationLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Bookings.Reservation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    live_action = socket.assigns.live_action
    socket = apply_live_action(params, live_action, socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"reservation" => params}, socket) do
    rooms = params["rooms"]
    reservation = Reservation.changeset(%Reservation{}, params) |> to_form(action: :validate)
    rooms_ids = Enum.map(rooms, fn {_, %{"room_id" => room_id}} -> String.to_integer(room_id) end)
    IO.inspect(reservation: reservation)

    socket =
      socket
      |> assign(reservation: reservation)
      |> assign(rooms: socket.assigns.rooms)

    {:noreply, socket}
  end

  defp room_label(room) do
    "#{room.number} - #{room.no_of_beds}"
  end

  defp apply_live_action(_params, :new, socket) do
    reservation_form = Bookings.new_reservation() |> to_form()
    rooms = Bookings.get_all_rooms() |> Enum.map(fn r -> {r.number, r.id} end)

    socket
    |> assign(action: :new)
    |> assign(reservation: reservation_form)
    |> assign(rooms: rooms)
  end

  defp apply_live_action(params, action, socket) do
    socket
    |> assign(action: action)
  end
end
