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
    {status, selected_rooms} = handle_rooms_selection(params["room_ids"])
    reservation = validate_reservation_form(params)

    socket =
      socket
      |> assign(room_selection_status: status)
      |> assign(selected_rooms: selected_rooms)
      |> assign(reservation: reservation)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"reservation" => params}, socket) do
    {status, selected_rooms} = handle_rooms_selection(params["room_ids"])

    if status == :error do
      socket =
        socket
        |> put_flash(:error, "Please select at least one room to continue!")
        |> assign(room_selection_status: status)

      {:noreply, socket}
    else
      case Bookings.create_reservation(params, selected_rooms) do
        {:ok, _reservation} ->
          socket
          |> put_flash(:info, "Reservation created!")
          |> push_patch(~p"/admin/reservations")

        {:error, changeset} ->
          reservation = changeset |> to_form(action: :insert)

          socket =
            socket
            |> assign(room_selected_status: status)
            |> assign(selected_rooms: selected_rooms)
            |> assign(reservation: reservation)
            |> put_flash(:error, "Please correct errors to continue!")

          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("check-in-date", %{"reservation" => %{"check_in" => check_in_date}}, socket) do
    check_in_date = Date.from_iso8601!(check_in_date)
    check_out_date = socket.assigns.check_out_date

    reservable_rooms =
      Bookings.reservable_rooms_for_period(check_in_date, check_out_date) |> rooms_list()

    socket =
      socket
      |> assign(rooms: reservable_rooms)
      |> assign(check_in_date: check_in_date)

    {:noreply, socket}
  end

  @impl true
  def handle_event("check-out-date", %{"reservation" => %{"check_out" => check_out_date}}, socket) do
    check_out_date = Date.from_iso8601!(check_out_date)
    check_in_date = socket.assigns.check_in_date

    reservable_rooms =
      Bookings.reservable_rooms_for_period(check_in_date, check_out_date) |> rooms_list()

    socket =
      socket
      |> assign(rooms: reservable_rooms)
      |> assign(check_out_date: check_out_date)

    {:noreply, socket}
  end

  ############# Reservations search ####################################
  @impl true
  def handle_event("search-reservations-by-id", %{"reservation_id" => ""}, socket) do
    reservations = Bookings.get_all_reservations()
    socket = assign(socket, reservations: reservations)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search-reservations-by-id", %{"reservation_id" => id}, socket) do
    id = id |> String.trim() |> String.to_integer()
    searched_reservations = Bookings.search_reservations_by_id(id)

    socket = assign(socket, reservations: searched_reservations)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search-reservations", %{"search_reservations" => search_params}, socket) do
    dbg(search_params)

    socket = socket |> assign(:search, true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset-search", _unsigned_params, socket) do
    IO.puts("++++++++++")
    socket = socket |> assign(:search, false)
    dbg(socket.assigns.search)
    {:noreply, socket}
  end

  #####################################################################

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    # Default value for check_in = Date.utc_today()
    check_in = Date.utc_today()
    # Default value for check_out = check_in + 1
    check_out = Date.shift(check_in, day: 1)
    reservation = new_reservation_form(check_in, check_out)
    socket = assign(socket, check_in_date: check_in)
    socket = assign(socket, check_out_date: check_out)
    rooms = Bookings.reservable_rooms_for_period(check_in, check_out) |> rooms_list()
    reservation_channels = Constants.reservation_channel_types()

    socket
    # |> assign(room_error: false)
    |> assign(action: :new)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(selected_rooms: [])
    |> assign(room_selection_status: nil)
    |> assign(reservation_channels: reservation_channels)
  end

  defp apply_live_action(_params, :index, socket) do
    reservations = Bookings.get_all_reservations()

    socket
    |> assign(search: false)
    |> assign(action: :index)
    |> assign(reservations: reservations)
  end

  #### EDIT ACTION ####
  defp apply_live_action(%{"id" => reservation_id}, :edit, socket) do
    reservation = Bookings.get_reservation(reservation_id)
    reservation_form = Bookings.Reservation.changeset(reservation) |> to_form()
    #    rooms = reservable_rooms()

    socket
    |> assign(action: :edit)
    # |> assign(rooms: rooms)
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
    |> Reservation.validate_changeset(reservation_params)
    |> to_form(action: :validate)
  end

  defp new_reservation_form(check_in, check_out) do
    Bookings.new_reservation(%{check_in: check_in, check_out: check_out}) |> to_form()
  end

  defp rooms_list(rooms) do
    Enum.map(rooms, fn room -> room_label(room) end)
  end

  defp room_label(room) do
    room_label = "#{room.number} - #{room.no_of_beds} bed(s)"
    %{label: room_label, id: room.id}
  end

  defp handle_rooms_selection(nil) do
    {:error, []}
  end

  defp handle_rooms_selection(room_ids) do
    selected_rooms =
      room_ids
      |> Enum.map(&String.to_integer/1)

    {:ok, selected_rooms}
  end

  # View helper to list numbers for reserved rooms
  def reserved_rooms([room]), do: "#{room.number}"

  def reserved_rooms(rooms) do
    Enum.reduce(rooms, "", fn room, acc ->
      acc <> "#{room.number} "
    end)
  end

  ##### RENDER FUNCTIONS #####
  @impl true
  def render(%{action: :index} = assigns) do
    ~H"""
    <h2>Reservations</h2>

    <div class="mt-4 flex flex-row gap-4 border-t">
      <.add_live_button route={~p"/admin/reservations/new"}>New reservation</.add_live_button>
      <.form
        :let={f}
        class="flex flex-row gap-2"
        for={%{}}
        as={:search_reservations}
        phx-submit="search-reservations"
      >
        <.input field={f[:guest_name]} type="text" placeholder="name" />
        <.input field={f[:guest_surname]} type="text" placeholder="surname" />
        <.input field={f[:check_in_date]} type="date" />
        <button>
          <.icon name="hero-magnifying-glass" />
        </button>
      </.form>
      <%= if @search do %>
        <button phx-click="reset-search">Reset search</button>
      <% end %>

      <.form :let={f} for={%{}} phx-change="search-reservations-by-id">
        <.input field={f[:reservation_id]} type="text" placeholder="reservation id" />
      </.form>
    </div>

    <.table
      id="reservations"
      rows={@reservations}
      row_click={fn reservation -> JS.patch(~p"/admin/reservations/#{reservation}/edit") end}
    >
      <:col :let={reservation} label="ID">{reservation.id}</:col>
      <:col :let={reservation} label="Check In">{date(reservation.check_in)}</:col>
      <:col :let={reservation} label="Check Out">{date(reservation.check_out)}</:col>
      <:col :let={reservation} label="Name">{reservation.guest_name}</:col>
      <:col :let={reservation} label="Surname">{reservation.guest_surname}</:col>
      <:col :let={reservation} label="Nights">{reservation.no_of_nights}</:col>
      <:col :let={reservation} label="Contact number">{reservation.contact_number}</:col>
      <:col :let={reservation} label="Channel">{reservation.channel}</:col>
      <:col :let={reservation} label="Rooms">{reserved_rooms(reservation.rooms)}</:col>
    </.table>
    """
  end

  def render(%{action: :new} = assigns) do
    ~H"""
    <h2>New reservation</h2>
    <div class="flex flex-row gap-4 mb-4">
      <div class="w-1/2">
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
            phx-change="check-in-date"
          />
          <.input
            field={@reservation[:check_out]}
            type="date"
            label="Check out"
            field_required={true}
            phx-change="check-out-date"
          />

          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            <span class="text-md text-red-500">*</span>Select available rooms
          </label>
          <%= if Enum.empty?(@rooms) do %>
            <p class="font-bold text-rose-500">
              No available rooms for selected period, please select new dates.
            </p>
          <% else %>
            <div class="grid grid-cols-2 gap-2 border-b-2 border-t-2">
              <%= for room <- @rooms do %>
                <div>
                  <label class="block text-sm font-semibold leading-6 text-zinc-800">
                    {room.label}
                    <input
                      type="checkbox"
                      class="rounded-md"
                      name="reservation[room_ids][]"
                      value={room.id}
                      checked={room.id in @selected_rooms}
                      %
                    />
                  </label>
                </div>
              <% end %>
            </div>
          <% end %>
          <%= if @room_selection_status == :error do %>
            <.error>At least one room must be selected!</.error>
          <% end %>

          <.input type="checkbox" name="breakfast" label="Breakfast" />
          <.input
            type="email"
            label="Email"
            field={@reservation[:contact_email]}
            field_required={true}
          />
          <.input
            type="tel"
            label="Phone number"
            field={@reservation[:contact_number]}
            field_required={true}
          />
          <.input type="text" label="Company name" field={@reservation[:company_name]} />
          <.input type="text" label="Company VAT number" field={@reservation[:company_vat]} />
          <.input
            type="select"
            label="Channel"
            field={@reservation[:channel]}
            options={@reservation_channels}
            field_required={true}
          />
          <.input type="textarea" field={@reservation[:notes]} label="Notes" />

          <:actions>
            <.button>Create</.button>
            <.link patch={~p"/admin/reservations"}>
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def render(%{action: :edit} = assigns) do
    ~H"""
    <h2>Edit reservation</h2>
    <div class="flex flex-row gap-4 mb-4">
      <div class="w-1/2">
        <.simple_form for={@reservation} phx-change="validate" phx-submit="create">
          <.input field={@reservation[:guest_name]} type="text" label="Name" field_required={true} />
          <.input
            field={@reservation[:guest_surname]}
            type="text"
            label="Surname"
            field_required={true}
          />
          <.input field={@reservation[:check_in]} type="date" label="Check in" field_required={true} />
          <.input field={@reservation[:no_of_nights]} type="text" label="Number of nights" disabled />
          <.input
            field={@reservation[:check_out]}
            type="date"
            label="Check out"
            field_required={true}
          />
          <%= if @room_error do %>
            <.error>{@room_error_message}</.error>
          <% end %>
          <!-- Begin Add Button -->
          <div>
            <label class="w-1/3 p-1 pr-2 rounded-full border border-black hover:border-zinc-500 cursor-pointer">
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
                value={room.index}
              />
              <div class="mt-auto">
                <label class="flex h-1/2 ml-10 rounded-full w-1/3 pr-2 py-1 border border-black hover:border-zinc-500 cursor-pointer">
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
          <.input
            type="email"
            label="Email"
            field={@reservation[:contact_email]}
            field_required={true}
          />
          <.input
            type="tel"
            label="Phone number"
            field={@reservation[:contact_number]}
            field_required={true}
          />
          <.input type="text" label="Company name" field={@reservation[:company_name]} />
          <.input type="text" label="Company VAT number" field={@reservation[:company_vat]} />
          <.input
            type="select"
            label="Channel"
            field={@reservation[:channel]}
            options={@reservation_channels}
            field_required={true}
          />
          <.input type="textarea" field={@reservation[:notes]} label="Notes" />

          <:actions>
            <.button phx-disable-with="Creating reservation...">Create</.button>
            <.link patch={~p"/admin/reservations"}>
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
