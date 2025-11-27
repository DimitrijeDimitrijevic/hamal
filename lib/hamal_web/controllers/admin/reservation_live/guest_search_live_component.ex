defmodule HamalWeb.Admin.ReservationLive.GuestSearchLiveComponent do
  use HamalWeb, :live_component
  alias Hamal.Clients

  @impl true
  def mount(socket) do
    socket = assign(socket, guests: [])
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("guest-search", params, socket) do
    guest_search_by = Map.get(params, "guest-search-by")
    guest_query = Map.get(params, "guest-query")

    guests =
      if guest_query != "", do: Clients.search_guests(guest_query, guest_search_by), else: []

    socket = assign(socket, guests: guests)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>Guest selection</h2>
      <div class="ml-2 mr-2">
        <.form for={%{}} phx-change="guest-search" phx-target={@myself} class="flex flex-row gap-2">
          <.input type="text" name="guest-query" value="" />
          <.input
            type="select"
            name="guest-search-by"
            options={[{"Name & Surname", "name_surname"}, {"Email", "email"}, {"Phone", "phone"}]}
            value=""
          />
        </.form>
      </div>
      <%= if not Enum.empty?(@guests) do %>
        <.table
          id="guets"
          rows={@guests}
          row_click={
            fn guest ->
              # To target this live component use option target: @myself
              JS.push("guest-selection", value: %{guest_id: guest.id})
            end
          }
        >
          <:col :let={guest} label="Name">{guest.name}</:col>
          <:col :let={guest} label="Surname">{guest.surname}</:col>
          <:col :let={guest} label="Email">{guest.email}</:col>
          <:col :let={guest} label="Phone">{guest.phone}</:col>
        </.table>
      <% end %>
    </div>
    """
  end
end
