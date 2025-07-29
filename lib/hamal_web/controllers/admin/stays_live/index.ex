defmodule HamalWeb.Admin.StaysLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Clients.Guest

  @impl true
  def mount(_params, _session, socket) do
    today = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_date()
    stays = Bookings.all_stays()
    socket = assign(socket, stays: stays, today: today)
    {:ok, socket}
  end

  # @impl true
  # def handle_params(unsigned_params, uri, socket) do
  #   dbg(unsigned_params)
  #   dbg(uri)
  #   live_action = socket.live_action
  #   dbg(live_action)
  #   {:noreply, socket}
  # end

  @impl true
  def handle_event("date-pick", %{"stays-date-pick" => date} = params, socket) do
    {:ok, date} = Date.from_iso8601(date)
    stays = Bookings.all_stays(date)

    dbg(stays)
    socket = assign(socket, stays: stays)

    {:noreply, socket}
  end

  @impl true
  def handle_event("check-out", %{"stay-id" => stay_id}, socket) do
    stay = Bookings.get_stay_by_id(stay_id)

    case Bookings.check_out_stay(stay) do
      {:ok, _stay} ->
        socket =
          socket
          |> put_flash(:info, "Successfully checked out")

        {:noreply, socket}

      {:error, _} ->
        socket = socket |> put_flash(:info, "Something went wrong!")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Current stays</h1>
    <div class="flex flex-row gap-2">
      <.form for={%{}} phx-change="date-pick">
        <.input type="date" value={@today} name="stays-date-pick" />
      </.form>
    </div>
    <.table rows={@stays} id="stays-table">
      <:col :let={stay} label="Room number">{stay.room.number}</:col>
      <:col :let={stay} label="Guest">{guest_name(stay.guest)}</:col>
      <:col :let={stay} label="Reservation">{stay.reservation_id}</:col>
      <:col :let={stay} label="Checked In">{stay.checked_in}</:col>
      <:col :let={stay} label="Checked Out">{stay.checked_out}</:col>
      <:col :let={stay} label="From">{date(stay.reservation.check_in)}</:col>
      <:col :let={stay} label="To">{date(stay.reservation.check_out)}</:col>
      <:action :let={stay}>
        <button phx-click="check-out" phx-value-stay-id={stay.id}>Check out</button>
      </:action>
    </.table>
    """
  end

  defp guest_name(%Guest{name: name, surname: surname}) do
    "#{name} #{surname}"
  end
end
