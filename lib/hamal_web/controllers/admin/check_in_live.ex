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

    {:ok, socket}
  end

  # we actions here not in handle params
  # extract here only what we need for processing later
  @impl true
  def handle_params(%{"reservation_id" => reservation_id}, _uri, socket) do
    reservation = Bookings.get_reservation(reservation_id)
    rooms = Enum.map(reservation.rooms, fn room -> {room.number, room.id} end)
    no_of_rooms = Enum.count(reservation.rooms)
    multi_select = if no_of_rooms > 1, do: true, else: false
    guest = %Guest{} |> Guest.check_in_changeset() |> to_form(action: :validate)

    socket =
      socket
      |> assign(reservation: reservation)
      |> assign(rooms: rooms)
      |> assign(multi_select: multi_select)
      |> assign(no_of_rooms: no_of_rooms)
      |> assign(guest: guest)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear-form", _unsigned_params, socket) do
    reservation = socket.assigns.reservation
    socket = push_patch(socket, to: ~p"/admin/check_in/#{reservation}")
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

  @impl true
  def handle_event("single-check-in", params, socket) do
    guest =
      if not is_nil(socket.assigns.guest_id), do: socket.assigns.guest.data, else: params["guest"]

    reservation = socket.assigns.reservation
    room = reservation.rooms |> List.first()

    socket =
      case Bookings.check_in_guest(reservation, room, guest) do
        {:ok, stay} ->
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
  end
end
