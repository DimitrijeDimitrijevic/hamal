defmodule HamalWeb.Admin.GuestLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Guests.Guest
  alias Hamal.Guests
  alias Hamal.Helpers.Constants

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Live action handlers, uri handler
  # Unsigned params are the params that are coming trought url/forms etc
  # Live action is coming from the router and assigned in socket
  @impl true
  def handle_params(unsigned_params, _uri, socket) do
    IO.inspect(socket_assigns: socket.assigns)
    live_action = socket.assigns.live_action
    socket = apply_live_action(unsigned_params, live_action, socket)
    {:noreply, socket}
  end

  # Handle events from the client
  @impl true
  def handle_event("save", %{"action" => "new", "guest" => guest_params}, socket) do
    IO.inspect(socket)

    case Guests.create_guest(guest_params) do
      {:ok, _guest} ->
        socket =
          socket
          |> put_flash(:info, "Guest created successfully")
          |> push_patch(to: ~p"/admin/guests")

        {:noreply, socket}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Please correct errors in inputs to continue!")
        socket = assign(socket, guest: to_form(changeset))
        {:noreply, socket}
    end
  end

  # Helper functions

  # applying live action from router with fields
  defp apply_live_action(_params, :new = action, socket) do
    doc_types = Constants.doc_types()
    countries = Constants.all_countries()

    socket
    |> assign(msg: "NEW")
    |> assign(title: "Add New Guest")
    |> assign(action: action)
    |> assign(doc_types: doc_types)
    |> assign(countries: countries)
    |> assign(guest: guest_data(action))
  end

  defp apply_live_action(_params, :index = action, socket) do
    socket
    |> assign(action: action)
    |> assign(guests: [])
  end

  defp apply_live_action(_params, _action, socket) do
    socket
    |> assign(action: nil)
  end

  # should accept changeset or map
  # but changeset for each guest

  defp guest_data(:new) do
    %Guest{}
    |> Guest.changeset(%{})
    |> to_form()
  end

  defp guest_data(:edit, guest_id) do
    Guest.get_guest(guest_id)
    |> Guest.changeset()
    |> to_form()
  end
end
