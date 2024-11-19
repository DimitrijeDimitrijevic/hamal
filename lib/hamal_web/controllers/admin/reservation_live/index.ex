defmodule HamalWeb.Admin.ReservationLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Bookings.Reservation
  alias Hamal.Helpers.Constants
  alias Hamal.Helpers.Reservation.Helper

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
    {room_error, room_error_msg} =
      validate_rooms_selection(params["rooms"]) |> handle_room_error()

    reservation = validate_reservation_form(params)

    socket =
      socket
      |> assign(room_error: room_error)
      |> assign(room_error_message: room_error_msg)
      |> assign(reservation: reservation)
      |> assign(rooms: socket.assigns.rooms)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"reservation" => params}, socket) do
    {room_error, room_error_msg} =
      validate_rooms_selection(params["rooms"]) |> handle_room_error()

    reservation = validate_reservation_form(params)

    if room_error do
      socket =
        socket
        |> assign(room_error: room_error)
        |> assign(room_error_message: room_error_msg)
        |> assign(reservation: reservation)
        |> assign(rooms: socket.assigns.rooms)
        |> put_flash(:error, "Please correct errors in inputs to continue!")

      {:noreply, socket}
    else
      room_ids = extract_room_ids(params["rooms"]) |> Enum.reject(&is_nil(&1)) |> Enum.uniq()

      case Bookings.create_reservation(params, room_ids) do
        {:ok, reservation} ->
          socket =
            socket
            |> put_flash(:info, "Reservation created successfully!")
            |> push_patch(to: ~p"/admin/reservations")

          {:noreply, socket}

        {:error, changeset} ->
          socket =
            socket
            |> assign(reservation: to_form(changeset, action: :insert))
            |> put_flash(:error, "Please correct errors in input to continue!")

          {:noreply, socket}
      end
    end
  end

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    reservation = Bookings.new_reservation() |> to_form()

    rooms = rooms_list()
    reservation_channels = Constants.reservation_channel_types()

    socket
    |> assign(room_error: false)
    |> assign(action: :new)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(reservation_channels: reservation_channels)
  end

  defp apply_live_action(params, action, socket) do
    socket
    |> assign(action: action)
  end

  ####################

  #### HELPER FUNCTIONS ####
  # Validation
  # Filters
  # Extractions
  #########################

  defp validate_reservation_form(reservation_params) do
    date_params =
      handle_no_of_nights(
        reservation_params["check_in"],
        reservation_params["check_out"],
        reservation_params["no_of_nights"]
      )

    reservation_params = update_dates_params(reservation_params, date_params)

    %Reservation{}
    |> Reservation.validation_changeset(reservation_params)
    |> to_form(action: :validate)
  end

  defp update_dates_params(reservation_params, {check_in, check_out, no_of_nights}) do
    reservation_params
    |> Map.put("check_in", check_in)
    |> Map.put("check_out", check_out)
    |> Map.put("no_of_nights", no_of_nights)
  end

  defp validate_rooms_selection(room_params) do
    room_ids = extract_room_ids(room_params)

    # Check if there is nil value in the list
    # Valid ids are the one which are integers, nil is not valid, that will be first selection
    valid_ids? =
      if is_nil(room_ids),
        do: false,
        else: Enum.all?(room_ids, fn room_id -> not is_nil(room_id) end)

    if valid_ids? do
      room_ids = Enum.reject(room_ids, fn id -> is_nil(id) end)
      unique_ids = Enum.uniq(room_ids)

      if Enum.count(unique_ids) == Enum.count(room_ids) do
        {:ok, :valid_selection}
      else
        {:error, :duplicate_selected}
      end
    else
      {:error, :not_selected}
    end
  end

  defp extract_room_ids(nil), do: nil

  defp extract_room_ids(rooms_params) do
    rooms_params
    |> Enum.map(fn {_, room} ->
      if room["room_id"] == "", do: nil, else: String.to_integer(room["room_id"])
    end)
  end

  defp rooms_list() do
    rooms = Bookings.get_reservable_rooms() |> Enum.map(&room_label/1)
    [{"Select room", nil} | rooms]
  end

  defp room_label(room) do
    {"#{room.number} - #{room.no_of_beds} bed(s)", room.id}
  end

  defp handle_room_error({:error, :duplicate_selected}),
    do: {true, "Duplicate rooms selected, please make sure you do not have same rooms selected."}

  defp handle_room_error({:error, :not_selected}),
    do: {true, "Please select at least one room per reservation"}

  defp handle_room_error({:ok, _}), do: {false, ""}

  defp handle_no_of_nights(check_in, "", ""), do: {check_in, nil, nil}

  defp handle_no_of_nights(check_in, check_out, "") do
    {check_in, check_out} = Helper.check_in_check_out_to_dates(check_in, check_out)
    no_of_nights = calculate_number_of_nights(check_in, check_out)

    {Date.to_string(check_in), Date.to_string(check_out), no_of_nights}
  end

  defp handle_no_of_nights(check_in, "", no_of_nights) do
    no_of_nights = String.to_integer(no_of_nights)
    {check_in, _} = Helper.check_in_check_out_to_dates(check_in, nil)
    check_out = check_in |> Date.shift(day: no_of_nights) |> Date.to_string()
    {check_in, check_out, no_of_nights}
  end

  defp handle_no_of_nights(check_in, check_out, no_of_nights)
       when check_out != "" or not is_nil(check_out) do
    {check_in, check_out} = Helper.check_in_check_out_to_dates(check_in, check_out)
    no_of_nights = String.to_integer(no_of_nights)
    new_dif_days = Date.diff(check_out, check_in)

    {check_out, no_of_nights} =
      if no_of_nights != new_dif_days do
        {check_out, calculate_number_of_nights(check_in, check_out)}
      else
        check_out = check_in |> Date.shift(day: no_of_nights)
        no_of_nights = calculate_number_of_nights(check_in, check_out)
        {check_out, no_of_nights}
      end

    {check_in, check_out, no_of_nights}
  end

  defp calculate_number_of_nights(check_in, check_out) do
    case Date.diff(check_out, check_in) do
      0 -> 1
      no_of_nights -> no_of_nights
    end
  end
end
