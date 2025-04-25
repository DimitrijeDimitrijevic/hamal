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
          Hamal.Emails.Bookings.confirmation_email(reservation)
          |> Hamal.Mailer.deliver()


          socket =
            socket
            |> put_flash(:info, "Reservation created successfully!")
            |> push_patch(to: ~p"/admin/reservations")

          {:noreply, socket}

        {:error, :other_failure} ->
          socket =
            socket
            |> put_flash(
              :error,
              "An error occurred while creating reservation. Please contact support!"
            )
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

  @impl true
  def handle_event(
        "filter-check-in-rooms",
        %{"reservation" => %{"check_in" => check_in_date}},
        socket
      ) do
    {:ok, check_in_date} = Date.from_iso8601(check_in_date)

    available_rooms = reservable_rooms(check_in_date)

    socket =
      socket
      |> assign(rooms: available_rooms)

    {:noreply, socket}
  end

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    reservation = Bookings.new_reservation() |> to_form()

    rooms = reservable_rooms()
    reservation_channels = Constants.reservation_channel_types()

    socket
    |> assign(room_error: false)
    |> assign(action: :new)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(reservation_channels: reservation_channels)
  end

  defp apply_live_action(_params, :index, socket) do
    reservations = Bookings.get_all_reservations()

    socket
    |> assign(action: :index)
    |> stream(:reservations, reservations)
  end

  #### EDIT ACTION ####
  defp apply_live_action(%{"id" => reservation_id}, :edit, socket) do
    reservation = Bookings.get_reservation(reservation_id)
    #  reserved_rooms = reservation.rooms
    reservation_form = Bookings.Reservation.changeset(reservation) |> to_form()
    rooms = reservable_rooms()

    socket
    |> assign(room_error: false)
    |> assign(action: :edit)
    |> assign(rooms: rooms)
    |> assign(reservation: reservation_form)
    |> assign(reservation_channels: Constants.reservation_channel_types())
  end

  defp apply_live_action(_params, action, socket) do
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
    %Reservation{}
    |> Reservation.changeset(reservation_params)
    |> to_form(action: :validate)
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

  defp rooms_list(rooms) do
    rooms = Enum.map(rooms, fn room -> room_label(room) end)
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

  # View helper to list numbers for reserved rooms
  def reserved_rooms([room]), do: "#{room.number}"

  def reserved_rooms(rooms) do
    Enum.reduce(rooms, "", fn room, acc ->
      acc <> "#{room.number} "
    end)
  end

  defp reservable_rooms(date), do: Bookings.get_reservable_rooms(date) |> rooms_list()
  defp reservable_rooms(), do: Bookings.get_reservable_rooms() |> rooms_list()

  ##### RENDER FUNTIONS #####
  @impl true
  def render(%{action: :index} = assigns) do
    ~H"""
    <.add_live_button link={~p"/admin/reservations/new"} action="Create Reservation" />

    <.table
      id="reservations"
      rows={@streams.reservations}
      row_click={fn {_id, reservation} -> JS.patch(~p"/admin/reservations/#{reservation}/edit") end}
    >
      <:col :let={{_id, reservation}} label="ID">{reservation.id}</:col>
      <:col :let={{_id, reservation}} label="Check In">{date(reservation.check_in)}</:col>
      <:col :let={{_id, reservation}} label="Check Out">{date(reservation.check_out)}</:col>
      <:col :let={{_id, reservation}} label="Name">{reservation.guest_name}</:col>
      <:col :let={{_id, reservation}} label="Surname">{reservation.guest_surname}</:col>
      <:col :let={{_id, reservation}} label="Nights">{reservation.no_of_nights}</:col>
      <:col :let={{_id, reservation}} label="Contact number">{reservation.contact_number}</:col>
      <:col :let={{_id, reservation}} label="Channel">{reservation.channel}</:col>
      <:col :let={{_id, reservation}} label="Rooms">{reserved_rooms(reservation.rooms)}</:col>
    </.table>
    """
  end

  def render(%{action: :new} = assigns) do
    ~H"""
    <h3> New reservation </h3>
    <p> Create new reservation </p>
    <div>
      <.simple_form for={@reservation} phx-change="validate" phx-submit="create">
        <.input field={@reservation[:guest_name]} type="text" label="Name" field_required={true} />
        <.input
          field={@reservation[:guest_surname]}
          type="text"
          label="Surname"
          field_required={true}
        />
        <.input
          field={@reservation[:check_in]}
          type="date"
          label="Check in"
          field_required={true}
          phx-change="filter-check-in-rooms"
          value={Date.utc_today()}
        />
        <%!-- <.input
          field={@reservation[:no_of_nights]}
          type="number"
          label="Number of nights"
          field_required={true}
          min="1"
          max="30"
        /> --%>
        <.input field={@reservation[:check_out]} type="date" label="Check out" field_required={true} />
        <%= if @room_error do %>
          <.error>{@room_error_message}</.error>
        <% end %>
        <!-- Begin Add Button -->
        <div class="grid">
          <label class="text-green-500 w-1/3 p-1 pr-2 rounded-full border border-green-500 cursor-pointer">
            <.icon name="hero-plus-circle" />
            <input class="hidden" type="checkbox" name="reservation[room_order][]" /> Add Room
          </label>
        </div>
        <!-- End Add Button -->
        <.inputs_for :let={room} field={@reservation[:rooms]}>
          <div class="grid grid-cols-2">
            <.input
              field={room[:room_id]}
              type="select"
              label="Select room/s"
              options={@rooms}
              field_required={true}
            />
            <div class="mt-auto">
              <label class="text-white flex bg-red-500 h-1/2 ml-10 rounded-full w-2/3 pr-2 py-1 border border-red-500 cursor-pointer">
                <.icon name="hero-minus-circle" />
                <input
                  class="hidden"
                  type="checkbox"
                  name="reservation[room_delete][]"
                  value={room.index}
                /> Delete
              </label>
            </div>
           </div>
        </.inputs_for>
        <.input type="checkbox" name="breakfast" label="Breakfast" />
        <.input type="email" label="Email" field={@reservation[:contact_email]} />
        <.input type="tel" label="Phone number" field={@reservation[:contact_number]} />
        <.input type="text" label="Company name" field={@reservation[:company_name]} />
        <.input type="text" label="Company VAT number" field={@reservation[:company_vat]} />
        <.input
          type="select"
          label="Channel"
          field={@reservation[:channel]}
          options={@reservation_channels}
        />
        <.input type="textarea" field={@reservation[:notes]} label="Notes" />

        <:actions>
          <.button phx-disable-with="Creating reservation..." class="w-1/2">Create</.button>
          <.link
            href={~p"/admin/reservations"}
            class="text-white bg-red-500 hover:bg-red-400 w-1/2 text-center rounded-lg py-2 px-3 font-semibold"
          >
            Cancel
          </.link>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def render(%{action: :edit} = assigns) do
    ~H"""
    <div class="mx-auto max-w-xl">
      <.simple_form for={@reservation} phx-change="validate" phx-submit="create">
        <.input field={@reservation[:guest_name]} type="text" label="Name" field_required={true} />
        <.input
          field={@reservation[:guest_surname]}
          type="text"
          label="Surname"
          field_required={true}
        />
        <.input
          field={@reservation[:check_in]}
          type="date"
          label="Check in"
          field_required={true}
          phx-change="filter-check-in-rooms"
          value={Date.utc_today()}
        />
        <.input
          field={@reservation[:no_of_nights]}
          type="number"
          label="Number of nights"
          field_required={true}
          min="1"
          max="30"
        />
        <.input field={@reservation[:check_out]} type="date" label="Check out" field_required={true} />
        <%= if @room_error do %>
          <.error>{@room_error_message}</.error>
        <% end %>
        <!-- Begin Add Button -->
        <div class="grid">
          <label class="text-green-500 w-1/3 p-1 pr-2 rounded-full border border-green-500 cursor-pointer">
            <.icon name="hero-plus-circle" />
            <input class="hidden" type="checkbox" name="reservation[room_order][]" /> Add Room
          </label>
        </div>
        <!-- End Add Button -->
        <.inputs_for :let={room} field={@reservation[:rooms]}>
          <div class="grid grid-cols-2">
            <.input
              field={room[:room_id]}
              type="select"
              label="Select room/s"
              options={@rooms}
              field_required={true}
            />
            <div class="mt-auto">
              <label class="text-white flex bg-red-500 h-1/2 ml-10 rounded-full w-2/3 pr-2 py-1 border border-red-500 cursor-pointer">
                <.icon name="hero-minus-circle" />
                <input
                  class="hidden"
                  type="checkbox"
                  name="reservation[room_delete][]"
                  value={room.index}
                /> Delete
              </label>
            </div>
          </div>
        </.inputs_for>
        <.input type="checkbox" name="breakfast" label="Breakfast" />
        <.input type="email" label="Email" field={@reservation[:contact_email]} />
        <.input type="tel" label="Phone number" field={@reservation[:contact_number]} />
        <.input type="text" label="Company name" field={@reservation[:company_name]} />
        <.input type="text" label="Company VAT number" field={@reservation[:company_vat]} />
        <.input
          type="select"
          label="Channel"
          field={@reservation[:channel]}
          options={@reservation_channels}
        />
        <.input type="textarea" field={@reservation[:notes]} label="Notes" />

        <:actions>
          <.button phx-disable-with="Creating reservation..." class="w-1/2">Create</.button>
          <.link
            href={~p"/admin/reservations"}
            class="text-white bg-red-500 hover:bg-red-400 w-1/2 text-center rounded-lg py-2 px-3 font-semibold"
          >
            Cancel
          </.link>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
