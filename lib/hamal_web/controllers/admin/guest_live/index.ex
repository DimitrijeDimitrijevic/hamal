defmodule HamalWeb.Admin.GuestLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Clients.Guest
  alias Hamal.Clients
  alias Hamal.Helpers.Constants

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Live action handlers, uri handler
  # Unsigned params are the params that are coming trought url/forms etc
  # Live action is coming from the router and assigned in socket
  @impl true
  def handle_params(params, _uri, socket) do
    live_action = socket.assigns.live_action
    socket = apply_live_action(params, live_action, socket)
    {:noreply, socket}
  end

  # Handle events from the client
  @impl true
  def handle_event("save", %{"action" => "new", "guest" => guest_params}, socket) do
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

  @impl true
  def handle_event("save", %{"action" => "edit", "guest" => guest_params}, socket) do
    guest = socket.assigns.guest_object

    case Clients.update_guest(guest, guest_params) do
      {:ok, guest} ->
        IO.inspect(guest)
        {:noreply, socket}

      {:error, changeset} ->
        IO.inspect(changeset)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", unsigned_params, socket) do
    IO.inspect(unsigned_params)
    {:noreply, socket}
  end

  # Helper functions

  # applying live action from router with fields
  defp apply_live_action(_params, :new = action, socket) do
    doc_types = Constants.doc_types()
    countries = Constants.all_countries()

    socket
    |> assign(title: "Add New Guest")
    |> assign(action: action)
    |> assign(doc_types: doc_types)
    |> assign(countries: countries)
    |> assign(guest: guest_data(action))
  end

  defp apply_live_action(_params, :index, socket) do
    guests = Clients.get_all_guests()

    socket
    |> assign(action: :index)
    |> assign(guests: guests)
  end

  defp apply_live_action(%{"id" => id}, :edit, socket) do
    {form, guest} = guest_form(:edit, id)
    doc_types = Constants.doc_types()
    countries = Constants.all_countries()

    socket
    |> assign(doc_types: doc_types)
    |> assign(countries: countries)
    |> assign(title: "Edit Guest")
    |> assign(action: :edit)
    |> assign(guest_object: guest)
    |> assign(guest: form)
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
    |> to_form(action: :validate)
  end

  defp guest_form(:edit, guest_id) do
    guest = Clients.get_guest(guest_id)

    form =
      guest
      |> Guest.changeset()
      |> to_form(action: :validate)

    {form, guest}
  end
end
