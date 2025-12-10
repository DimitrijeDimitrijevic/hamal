defmodule HamalWeb.Admin.CheckInLive do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Clients.Guest
  alias Hamal.Clients

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(selected_guests: [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    reservation_id = Map.get(params, "reservation_id")
    reservation = Bookings.get_reservation(reservation_id)

    socket = assign(socket, reservation: reservation)

    {:noreply, socket}
  end

  # @impl true
  # def handle_event("guest-selection", %{"guest_id" => guest_id}, socket) do
  #   guest = Clients.get_guest(guest_id)
  #   socket = assign(socket, :selected_guests, [guest | socket.assigns.selected_guests])
  #   {:noreply, socket}
  # end
  #
  @impl true
  def handle_info({:add_guest, guest}, socket) do
    dbg(socket.assigns)
    selected_guests = socket.assigns.selected_guests

    if Enum.member?(selected_guests, guest) do
      socket =
        socket
        |> put_flash(:error, "Guest already added!")

      {:noreply, socket}
    else
      socket = assign(socket, :selected_guests, [guest | selected_guests])
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={HamalWeb.Admin.ReservationLive.GuestSearchLiveComponent}
      id={@reservation.id}
    />
    <div>
      <%= for guest <- @selected_guests do %>
        <p phx-click="remove-guest" phx-value-guest_id={guest.id}>{guest.name}</p>
      <% end %>
    </div>
    <.button phx-click="add-guest">+</.button>
    <.form for={%{}} phx-submit="add guests"></.form>
    """
  end
end
