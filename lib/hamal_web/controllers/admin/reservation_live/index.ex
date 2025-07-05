defmodule HamalWeb.Admin.ReservationLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Bookings.Reservation
  alias Hamal.Helpers.Constants

  @impl true
  def mount(_params, _session, socket) do
    reservation_channels = Constants.reservation_channel_types()

    socket =
      socket
      |> assign(room_selection_status: nil)
      |> assign(reservation_channels: reservation_channels)

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

  @doc """
  Handling creating reservations in LiveView process.
  """
  @impl true
  def handle_event("create", %{"reservation" => params}, socket) do
    {status, selected_rooms_ids} = handle_rooms_selection(params["room_ids"])

    if status == :error do
      socket =
        socket
        |> put_flash(:error, "Please select at least one room to continue!")
        |> assign(room_selection_status: status)

      {:noreply, socket}
    else
      socket =
        case Bookings.create_reservation(params, selected_rooms_ids) do
          {:ok, _reservation} ->
            socket
            |> put_flash(:info, "Reservation created!")
            |> push_patch(to: ~p"/admin/reservations")

          {:error, :other_failure} ->
            socket
            |> put_flash(:error, "Something went wrong. Please contact support.")
            |> push_patch(to: ~p"/admin/reservations")

          {:error, changeset} ->
            reservation = changeset |> to_form(action: :insert)

            socket
            |> assign(room_selected_status: status)
            |> assign(selected_rooms: selected_rooms_ids)
            |> assign(reservation: reservation)
            |> put_flash(:error, "Please correct errors to continue!")
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update", %{"reservation" => params}, socket) do
    {status, selected_rooms_ids} = handle_rooms_selection(params["room_ids"])

    if status == :error do
      socket =
        socket
        |> put_flash(:error, "Please select at least one room to continue!")
        |> assign(room_selection_status: status)

      {:noreply, socket}
    else
      reservation_id = socket.assigns.reservation_id

      socket =
        case Bookings.update_reservation(reservation_id, params, selected_rooms_ids) do
          {:ok, reservation} ->
            socket
            |> put_flash(:info, "Reservation #{reservation.id} updated!")
            |> push_patch(to: ~p"/admin/reservations")

          {:error, changeset} ->
            reservation = changeset |> to_form(action: :update)

            socket
            |> assign(room_selected_status: status)
            |> assign(selected_rooms: selected_rooms_ids)
            |> assign(reservation: reservation)
            |> put_flash(:error, "Please correct errors to continue!")
        end

      {:noreply, socket}
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

  @impl true
  def handle_event("start-check-in", %{"value" => reservation_id}, socket) do
    reservation = String.to_integer(reservation_id) |> Bookings.get_reservation()

    {:norepley, socket}
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
    reservations = Bookings.search_reservations_by_id(id)

    socket = assign(socket, reservations: reservations)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search-reservations", %{"search_reservations" => search_params}, socket) do
    reservations = Bookings.search_reservations(search_params)
    socket = socket |> assign(:search, true) |> assign(reservations: reservations)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset-search", _unsigned_params, socket) do
    search_params = search_params()

    socket =
      socket
      |> assign(search_params: search_params)
      |> assign(search: false)
      |> push_navigate(to: ~p"/admin/reservations")

    {:noreply, socket}
  end

  #####################################################################

  defp apply_live_action(_params, :index, socket) do
    reservations = Bookings.get_all_reservations()

    search_params = search_params()

    socket
    |> assign(search_params: search_params)
    |> assign(search: false)
    |> assign(action: :index)
    |> assign(reservations: reservations)
  end

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    # Default value for check_in = Date.utc_today()
    check_in = Date.utc_today()
    # Default value for check_out = check_in + 1
    check_out = Date.shift(check_in, day: 1)
    reservation = new_reservation_form(check_in, check_out)
    rooms = Bookings.reservable_rooms_for_period(check_in, check_out) |> rooms_list()

    socket
    |> assign(action: :new)
    |> assign(check_in_date: check_in)
    |> assign(check_out_date: check_out)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(selected_rooms: [])
  end

  #### EDIT ACTION ####
  defp apply_live_action(%{"id" => reservation_id}, :edit, socket) do
    reservation = Bookings.get_reservation(reservation_id)
    reservation_form = Bookings.Reservation.changeset(reservation) |> to_form()
    selected_rooms = reservation.rooms |> Enum.map(fn room -> room.id end)

    rooms =
      Bookings.reservable_rooms_for_period(reservation.check_in, reservation.check_out)

    rooms =
      [rooms | reservation.rooms] |> List.flatten() |> rooms_list() |> Enum.sort_by(& &1.id, :asc)

    socket
    |> assign(check_in_date: reservation.check_in)
    |> assign(check_out_date: reservation.check_out)
    |> assign(reservation_id: reservation.id)
    |> assign(rooms: rooms)
    |> assign(selected_rooms: selected_rooms)
    |> assign(action: :edit)
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

  defp search_params() do
    %{"check_in_date" => nil, "guest_name" => nil, "guest_surname" => nil}
    |> to_form(as: :search_reservations)
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
      <.form class="flex flex-row gap-2" for={@search_params} phx-submit="search-reservations">
        <.input field={@search_params[:guest_name]} type="text" placeholder="Guest name" />
        <.input field={@search_params[:guest_surname]} type="text" placeholder="Guest surname" />
        <.input field={@search_params[:check_in_date]} type="date" />
        <button>
          <.icon name="hero-magnifying-glass" />
        </button>
      </.form>
      <%= if @search do %>
        <button type="button" phx-click="reset-search">Reset</button>
      <% end %>

      <.form :let={f} for={%{}} phx-change="search-reservations-by-id">
        <.input field={f[:reservation_id]} type="text" placeholder="Reservation Id" />
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
      <:action :let={reservation}>
        <button value={reservation.id} phx-click="start-check-in">Check in</button>
      </:action>
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

          <.input type="checkbox" field={@reservation[:breakfast]} label="Breakfast" />
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
            <.button>Save</.button>
            <.link class="underline" patch={~p"/admin/reservations"}>
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @doc """
  Edit form for reservation!
  """
  def render(%{action: :edit} = assigns) do
    ~H"""
    <h2>Edit reservation {@reservation_id}</h2>
    <div class="flex flex-row gap-4 mb-4">
      <div class="w-1/2">
        <.simple_form for={@reservation} phx-change="validate" phx-submit="update">
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
                      class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
                      name="reservation[room_ids][]"
                      value={room.id}
                      checked={room.id in @selected_rooms}
                    />
                  </label>
                </div>
              <% end %>
            </div>
          <% end %>
          <%= if @room_selection_status == :error do %>
            <.error>At least one room must be selected!</.error>
          <% end %>

          <.input type="checkbox" field={@reservation[:breakfast]} label="Breakfast" />
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
            <.button>Save</.button>
            <.button
              class="bg-gray-600"
              phx-click="start-check-in"
              data-confirm={"Start check in for reservation #{@reservation_id}?"}
            >
              Check in
            </.button>
            <.button
              data-confirm={"Delete reservation #{@reservation_id} ?"}
              class="bg-red-500"
              phx-click="delete"
            >
              Delete
            </.button>
            <.link class="underline" patch={~p"/admin/reservations"}>
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
