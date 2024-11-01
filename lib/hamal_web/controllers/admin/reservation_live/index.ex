defmodule HamalWeb.Admin.ReservationLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Bookings.Reservation
  alias Hamal.Helpers.Constants

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
    room_error = params["rooms"] |> is_nil()

    reservation = validate_reservation_form(params)

    socket =
      socket
      |> assign(room_error: room_error)
      |> assign(reservation: reservation)
      |> assign(rooms: socket.assigns.rooms)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"reservation" => params}, socket) do
    rooms = params["rooms"]
    room_error = is_nil(rooms)

    if room_error do
      reservation = validate_reservation_form(params)

      socket =
        socket
        |> assign(room_error: room_error)
        |> assign(reservation: reservation)
        |> assign(rooms: socket.assigns.rooms)
        |> put_flash(:error, "Please select at least one room to make reservation.")

      {:noreply, socket}
    else
      room_ids = extract_room_ids(rooms)

      case Bookings.create_reservation(params, room_ids) do
        {:ok, reservation} ->
          IO.inspect(reservation: reservation)
          {:noreply, socket}

        {:error, changeset} ->
          IO.inspect(changeset: changeset)
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("check-in-change", unsigned_params, socket) do
    # Get date of check-in and get available rooms from reservations on that date
    # then exclude those rooms from the list of rooms which is in assigns
    {:noreply, socket}
  end

  # @impl true
  # def handle_event("check-out-change", unsigned_params, socket) do
  #   {:noreply, socket}
  # end

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    reservation = Bookings.new_reservation() |> to_form()
    rooms = Bookings.get_reservable_rooms() |> Enum.map(&room_label/1)
    reservation_channels = Constants.reservation_channel_types()

    socket
    |> assign(room_error: false)
    |> assign(action: :new)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(reservation_channels: reservation_channels)
  end

  ####################

  defp validate_reservation_form(reservation_params) do
    %Reservation{}
    |> Reservation.validation_changeset(reservation_params)
    |> to_form(action: :validate)
  end

  defp apply_live_action(params, action, socket) do
    socket
    |> assign(action: action)
  end

  defp room_label(room) do
    {"#{room.number} - #{room.no_of_beds} bed(s)", room.id}
  end

  defp extract_room_ids(rooms_params) do
    rooms_params |> Enum.map(fn {_, room} -> room["room_id"] |> String.to_integer() end)
  end
end
