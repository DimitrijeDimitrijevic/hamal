defmodule HamalWeb.Admin.CheckInLive do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Clients.Guest
  alias Hamal.Clients

  import HamalWeb.Admin.CheckInLive.Helpers

  @impl true
  def mount(_params, _session, socket) do
    doc_types = Hamal.Helpers.Constants.doc_types()
    countries = Hamal.Helpers.Constants.all_countries()

    {:ok,
     socket
     |> assign(selected_guests: [])
     |> assign(new_guest_form: false)
     |> assign(guest_form: %{})
     |> assign(doc_types: doc_types)
     |> assign(countries: countries)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    reservation = Map.get(params, "reservation_id") |> Bookings.get_reservation()
    room = Map.get(params, "room_no") |> String.to_integer() |> Bookings.get_room_by_number()

    socket = socket |> assign(reservation: reservation) |> assign(room: room)

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-guest", %{"guest_id" => guest_id}, socket) do
    guest_id = if is_binary(guest_id), do: String.to_integer(guest_id), else: guest_id

    selected_guests = Enum.reject(socket.assigns.selected_guests, fn sg -> sg.id == guest_id end)
    socket = assign(socket, selected_guests: selected_guests)

    {:noreply, socket}
  end

  @impl true
  def handle_event("new-guest-form", _params, socket) do
    new_guest_form = if socket.assigns.new_guest_form, do: false, else: true

    if new_guest_form do
      guest_form = Hamal.Clients.new_guest() |> to_form(action: :validate)
      socket = socket |> assign(new_guest_form: new_guest_form, guest_form: guest_form)
      {:noreply, socket}
    else
      {:noreply, socket |> assign(new_guest_form: new_guest_form)}
    end
  end

  @impl true
  def handle_event("close-new-guest-form", _unsigned_params, socket) do
    {:noreply, assign(socket, new_guest_form: false)}
  end

  @impl true
  def handle_event("create-guest", %{"guest" => guest_params}, socket) do
    case Clients.create_guest(guest_params, :guest) do
      {:ok, guest} ->
        socket = socket |> assign(new_guest_form: false)
        send(self(), {:add_guest, guest})
        {:noreply, socket}

      {:error, changeset} ->
        guest_form = changeset |> to_form(action: :validate)

        {:noreply,
         socket |> put_flash(:error, "Check error in inputs!") |> assign(guest_form: guest_form)}
    end

    socket = socket |> assign(new_guest_form: false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:add_guest, guest}, socket) do
    selected_guests = socket.assigns.selected_guests

    room = socket.assigns.room

    if Enum.member?(selected_guests, guest) do
      {:noreply,
       socket
       |> put_flash(:error, "Guest already added!")}
    else
      selected_guests = [guest | selected_guests]

      if room_max_occupancy_reached?(selected_guests, room) do
        {:noreply, socket |> put_flash(:error, "Max occupancy for this room is reached! ")}
      else
        socket = assign(socket, :selected_guests, selected_guests)
        {:noreply, socket}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="font-bold">Reservation {@reservation.id} check in {@room.number}</h1>
    <.live_component
      module={HamalWeb.Admin.ReservationLive.GuestSearchLiveComponent}
      id={@reservation.id}
    />
    <%= if not Enum.empty?(@selected_guests) do %>
      <div class="p-4 border-2 rounded border-orange-300">
        <h3>Guests to check-in in room {@room.number}</h3>
        <.table id="selected-guests" rows={@selected_guests}>
          <:col :let={guest} label="Name">{guest.name}</:col>
          <:col :let={guest} label="Surname">{guest.surname}</:col>
          <:col :let={guest} label="Email">{guest.email}</:col>
          <:col :let={guest} label="Phone">{guest.phone}</:col>
          <:col :let={guest} label="Document type">{guest.document_type}</:col>
          <:col :let={guest} label="Document number">{guest.document_number}</:col>
          <:action :let={guest}>
            <button class="text-red-500 mr-2" phx-click="remove-guest" phx-value-guest_id={guest.id}>
              Remove
            </button>
          </:action>
        </.table>
        <.button class="mt-1">Check in</.button>
      </div>
    <% end %>
    <%= if @new_guest_form do %>
      <button phx-click="close-new-guest-form">- Close new guest form</button>
    <% else %>
      <button phx-click="new-guest-form">+ New guest form</button>
    <% end %>
    <%= if @new_guest_form do %>
      <.form for={@guest_form} id="new-guest-form" phx-submit="create-guest">
        <.input field={@guest_form[:name]} label="Name" field_required={true} placeholder="John" />
        <.input field={@guest_form[:surname]} label="Surname" field_required={true} placeholder="Doe" />
        <.input
          field={@guest_form[:birth_date]}
          type="date"
          label="Date of birth"
          field_required={true}
        />
        <.input
          field={@guest_form[:email]}
          type="email"
          label="Email"
          required={true}
          placeholder="email@gmail.com"
        />
        <.input
          field={@guest_form[:phone]}
          type="tel"
          label="Phone"
          required={true}
          placeholder="0601234567"
        />
        <.input
          field={@guest_form[:country]}
          type="text"
          list="countries"
          label="Country"
          field_required={true}
          placeholder="Start typing to get the list of countries, e.g Serbia"
        />
        <datalist id="countries">
          <option :for={country <- @countries}>
            {country}
          </option>
        </datalist>
        <.input field={@guest_form[:city]} label="City" field_required={true} placeholder="Istanbul" />
        <.input
          field={@guest_form[:address]}
          label="Address"
          field_required={true}
          placeholder="Street 100"
        />
        <.input
          field={@guest_form[:document_type]}
          label="Document type"
          type="select"
          options={@doc_types}
          field_required={true}
        />
        <.input
          field={@guest_form[:document_number]}
          label="Document number"
          field_required={true}
          placeholder="xyz1234"
        />

        <.input
          field={@guest_form[:notes]}
          type="textarea"
          label="Notes"
          placeholder="Notes about guests...what are preferences, likes, important information to know!"
        />
        <.button class="mt-2">Add</.button>
      </.form>
    <% end %>
    """
  end

  # make two action buttons here one edit/show one remove
  #  row_click={fn guest -> JS.push("remove-guest", value: %{guest_id: guest.id}) end}
end
