defmodule HamalWeb.Admin.CheckInLive do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Clients.Guest
  alias Hamal.Clients

  @impl true
  def mount(_params, _session, socket) do
    doc_types = Hamal.Helpers.Constants.doc_types()

    socket =
      socket
      |> assign(guest_search: false)
      |> assign(doc_types: doc_types)
      |> assign(guest_id: nil)
      |> assign(start_check_in: false)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"reservation_id" => reservation_id}, _uri, socket) do
    reservation = Bookings.get_reservation(reservation_id)
    rooms = Enum.map(reservation.rooms, fn room -> {room.number, room.id} end)
    multi_select = if Enum.count(reservation.rooms) > 1, do: true, else: false

    guest = new_guest()

    socket =
      socket
      |> assign(reservation: reservation)
      |> assign(rooms: rooms)
      |> assign(multi_select: multi_select)
      |> assign(guest: guest)

    {:noreply, socket}
  end

  @impl true
  def handle_event("guest-search", _unsigned_params, socket) do
    guest_search = if socket.assigns.guest_search, do: false, else: true

    {:noreply, assign(socket, guest_search: guest_search)}
  end

  @impl true
  def handle_event("guest-selection", %{"guest_id" => guest_id}, socket) do
    guest =
      Clients.get_guest(guest_id)

    guest_id = guest.id
    guest = Guest.check_in_changeset(guest) |> to_form(action: :validate)

    socket = assign(socket, guest: guest, guest_id: guest_id)
    {:noreply, socket}
  end

  # Used for rooms which one bed, current logic, actually should go from room settings
  @impl true
  def handle_event("single-check-in", params, socket) do
    guest =
      if not is_nil(socket.assigns.guest_id), do: socket.assigns.guest.data, else: params["guest"]

    reservation = socket.assigns.reservation
    [room] = reservation.rooms

    socket =
      case Bookings.check_in_guest(reservation, room, guest) do
        {:ok, stay, guest} ->
          socket
          |> put_flash(
            :info,
            "Guest #{guest.name} #{guest.surname} checked in room ##{room.number} with stay ID #{stay.id}!"
          )
          |> push_navigate(to: ~p"/admin/stays")

        {:error, changeset} ->
          guest = changeset |> to_form(action: :validate)

          socket
          |> assign(guest: guest)
          |> put_flash(:error, "Please correct errors in inputs to continue!")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("multi-check-in", %{"room-id" => room_id}, socket) do
    # Here the form is getting rendered
    room = Bookings.get_room(room_id)
    reservation = socket.assigns.reservation
    max_number_of_guests = room.no_of_beds
    current_stays = Bookings.current_guests_in_room_count(room.id, reservation)

    if current_stays >= max_number_of_guests do
      socket =
        socket
        |> assign(start_check_in: false)
        |> put_flash(
          :error,
          "Room #{room.number} full for this reservation. Choose another one to check-in guests."
        )
        |> push_patch(to: ~p"/admin/check_in/#{reservation}")

      {:noreply, socket}
    else
      socket =
        socket
        |> assign(room: room)
        |> assign(start_check_in: true)

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("multi-check-in-guest-submit", params, socket) do
    guest =
      if not is_nil(socket.assigns.guest_id), do: socket.assigns.guest.data, else: params["guest"]

    reservation = socket.assigns.reservation
    room = socket.assigns.room

    socket =
      case Bookings.check_in_guest(reservation, room, guest) do
        {:ok, stay, guest} ->
          socket
          |> assign(guest: new_guest())
          |> assign(guest_search: false)
          |> put_flash(
            :info,
            "Guest #{guest.name} #{guest.surname} checked in room ##{room.number} with stay ID #{stay.id}!"
          )
          |> push_patch(to: ~p"/admin/check_in/#{reservation}")

        {:error, guest_changeset} ->
          socket
          |> assign(guest: guest_changeset |> to_form(action: :validate))
          |> put_flash(:error, "Please correct erros in input to continue!")
      end

    {:noreply, socket}
  end

  defp new_guest() do
    %Guest{} |> Guest.check_in_changeset() |> to_form(action: :validate)
  end

  @impl true
  def render(%{multi_select: false} = assigns) do
    ~H"""
    <h1 class="underline">Check in for reservation #{@reservation.id}</h1>
    <p>Room Number: #{@rooms |> List.first() |> elem(0)}</p>
    <div class="flex flex-row gap-4 mb-4">
      <div class="w-1/2">
        <button class="mt-4 mb-2" phx-click="guest-search">
          <.icon name="hero-user-plus" />Select guest
        </button>
        <.simple_form for={@guest} phx-submit="single-check-in">
          <.input type="text" field={@guest[:name]} label="Name" field_required={true} />
          <.input type="text" field={@guest[:surname]} label="Surname" field_required={true} />
          <.input
            type="select"
            options={@doc_types}
            field={@guest[:document_type]}
            label="Document type"
            field_required={true}
          />
          <.input
            type="text"
            field={@guest[:document_number]}
            label="Document number"
            field_required={true}
          />
          <.input type="text" field={@guest[:phone]} label="Phone" />
          <.input type="text" field={@guest[:email]} label="Email" />
          <:actions>
            <.button class="mt-4">Check-in</.button>
            <.link class="underline" navigate={~p"/admin/reservations/#{@reservation}/edit"}>
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </div>
      <%= if @guest_search do %>
        <.live_component
          module={HamalWeb.Admin.ReservationLive.GuestSearchLiveComponent}
          id="check-in-guest-search"
          selection="Check-In"
        />
      <% end %>
    </div>
    """
  end

  @impl true
  def render(%{multi_select: true} = assigns) do
    ~H"""
    <h1 class="underline">Check in for reservation #{@reservation.id}</h1>
    <div class="w-1/2">
      <%= if @start_check_in do %>
        <p>Room Number: {@room.number}</p>
        <div class="flex flex-row gap-4 mb-4">
          <div class="w-1/2">
            <button class="mt-4 mb-2" phx-click="guest-search">
              <.icon name="hero-user-plus" />Select guest
            </button>
            <.simple_form for={@guest} phx-submit="multi-check-in-guest-submit">
              <.input type="text" field={@guest[:name]} label="Name" field_required={true} />
              <.input type="text" field={@guest[:surname]} label="Surname" field_required={true} />
              <.input
                type="select"
                options={@doc_types}
                field={@guest[:document_type]}
                label="Document type"
                field_required={true}
              />
              <.input
                type="text"
                field={@guest[:document_number]}
                label="Document number"
                field_required={true}
              />
              <.input type="text" field={@guest[:phone]} label="Phone" field_required={true} />
              <.input type="text" field={@guest[:email]} label="Email" field_required={true} />
              <:actions>
                <.button class="mt-4">Check-in</.button>
                <.link class="underline" navigate={~p"/admin/reservations/#{@reservation}/edit"}>
                  Cancel
                </.link>
              </:actions>
            </.simple_form>
          </div>
          <%= if @guest_search do %>
            <.live_component
              module={HamalWeb.Admin.ReservationLive.GuestSearchLiveComponent}
              id="check-in-guest-search"
              selection="Check-In"
            />
          <% end %>
        </div>
      <% else %>
        <div class="grid grid-cols-4 gap-6 mt-4">
          <%= for {room_number, room_id} <- @rooms do %>
            <button class="border-2 rounded-md" phx-click="multi-check-in" phx-value-room-id={room_id}>
              {room_number}
            </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
