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

    # {room_error, room_error_msg} =
    #   validate_rooms_selection(params["rooms"]) |> handle_room_error()

    # reservation = validate_reservation_form(params)

    # socket =
    #   socket
    #   |> assign(room_error: room_error)
    #   |> assign(room_error_message: room_error_msg)
    #   |> assign(reservation: reservation)
    #   |> assign(rooms: socket.assigns.rooms)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"reservation" => params}, socket) do


      {:noreply, socket}

    #   case Bookings.create_reservation(params, room_ids) do
    #     {:ok, reservation} ->
    #       Hamal.Emails.Bookings.confirmation_email(reservation)
    #       |> Hamal.Mailer.deliver()


    #       socket =
    #         socket
    #         |> put_flash(:info, "Reservation created successfully!")
    #         |> push_patch(to: ~p"/admin/reservations")

    #       {:noreply, socket}

    #     {:error, :other_failure} ->
    #       socket =
    #         socket
    #         |> put_flash(
    #           :error,
    #           "An error occurred while creating reservation. Please contact support!"
    #         )
    #         |> push_patch(to: ~p"/admin/reservations")

    #       {:noreply, socket}

    #     {:error, changeset} ->
    #       socket =
    #         socket
    #         |> assign(reservation: to_form(changeset, action: :insert))
    #         |> put_flash(:error, "Please correct errors to continue!")

    #       {:noreply, socket}
    #   end
    # end
  end


  ############# Reservations search ####################################
  @impl true
  def handle_event("search-reservations", %{"reservation_id" => ""}, socket) do
    reservations = Bookings.get_all_reservations()
    socket = assign(socket, reservations: reservations)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search-reservations", %{"reservation_id" => id}, socket) do
    id = id |> String.trim() |> String.to_integer()
    searched_reservations = Bookings.search_reservations_by_id(id)

    socket = assign(socket, reservations: searched_reservations)

   {:noreply, socket}
  end
  #####################################################################

  #### NEW ACTION ####
  defp apply_live_action(_params, :new, socket) do
    today = Date.utc_today()
    reservation = Bookings.new_reservation(%{check_in: today}) |> to_form()

    rooms = Bookings.get_reservable_rooms() |> rooms_list()
    reservation_channels = Constants.reservation_channel_types()


    socket
    # |> assign(room_error: false)
    |> assign(action: :new)
    |> assign(reservation: reservation)
    |> assign(rooms: rooms)
    |> assign(reservation_channels: reservation_channels)
  end

  defp apply_live_action(_params, :index, socket) do
    reservations = Bookings.get_all_reservations()

    socket
    |> assign(action: :index)
    |> assign(reservations: reservations)
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

  defp rooms_list(rooms) do
    Enum.map(rooms, fn room -> room_label(room) end)
  end

  defp room_label(room) do
    room_label = "#{room.number} - #{room.no_of_beds} bed(s)"
    %{label: room_label, id: room.id}
  end


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
    <h2> Reservations </h2>

    <div class="mt-4 flex flex-row gap-4 border-t">
    <.add_live_button route={~p"/admin/reservations/new"}> Create reservation </.add_live_button>
    <.form :let={f} for={%{}} phx-change="search-reservations">
    <.input field={f[:reservation_id]}  type="text" placeholder="reservation id"/>
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

  # def render(%{action: :new1} = assigns) do
  #     ~H"""
  #     <.form for={@reservation} phx-submit="create">
  #     <div class="grid grid-cols-4 gap-1">
  #     <%= for room <- @rooms do %>
  #       <div>
  #       <label for={room.id}> {room.number} - {room.no_of_beds}
  #         <input type="checkbox" class=""  name="reservation[room_ids][]" value={room.id} %>
  #       </label>
  #       </div>
  #     <% end %>
  #     </div>
  #       <.button> Submit </.button>
  #     </.form>
  #     """
  # end

  def render(%{action: :new} = assigns) do
    ~H"""
    <h2> New reservation </h2>
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
        />
        <.input
          field={@reservation[:no_of_nights]}
          type="text"
          label="Number of nights"
          disabled
        />
        <.input field={@reservation[:check_out]} type="date" label="Check out" field_required={true} />

        <label class="block text-sm font-semibold leading-6 text-zinc-800"> <span class="text-md text-red-500">*</span>Select available rooms </label>
        <div class="grid grid-cols-2 gap-2 border-b-2 border-t-2">
        <%= for room <- @rooms do %>
          <div>
          <label class="block text-sm font-semibold leading-6 text-zinc-800"> {room.label}
            <input type="checkbox" class="rounded-md" name="reservation[room_ids][]" value={room.id} %>
          </label>
          </div>
        <% end %>
        </div>
        <%!-- <%= if @room_error do %>
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
        </.inputs_for> --%>
        <.input type="checkbox" name="breakfast" label="Breakfast" />
        <.input type="email" label="Email" field={@reservation[:contact_email]} field_required={true}/>
        <.input type="tel" label="Phone number" field={@reservation[:contact_number]}  field_required={true}/>
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
          <.link
            patch={~p"/admin/reservations"}
          >
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
    <h2> Edit reservation </h2>
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
        />
        <.input
          field={@reservation[:no_of_nights]}
          type="text"
          label="Number of nights"
          disabled
        />
        <.input field={@reservation[:check_out]} type="date" label="Check out" field_required={true} />
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
        <.input type="email" label="Email" field={@reservation[:contact_email]} field_required={true}/>
        <.input type="tel" label="Phone number" field={@reservation[:contact_number]}  field_required={true}/>
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
          <.link
            patch={~p"/admin/reservations"}
          >
            Cancel
          </.link>
        </:actions>
      </.simple_form>
    </div>
    </div>
    """
  end
end
