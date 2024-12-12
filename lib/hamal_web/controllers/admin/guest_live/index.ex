defmodule HamalWeb.Admin.GuestLive.Index do
  use HamalWeb, :live_view
  alias Hamal.Clients.Guest
  alias Hamal.Clients
  alias Hamal.Helpers.Constants
  alias Hamal.Paginator

  @first_page 0

  @impl true
  def mount(_params, _session, socket) do
    search_form = %{"query" => nil, "type" => nil} |> to_form(as: :search)
    socket = assign(socket, search_form: search_form)
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
    case Clients.create_guest(guest_params, :guest) do
      {:ok, _guest} ->
        socket =
          socket
          |> put_flash(:info, "Guest created successfully")
          |> push_patch(to: ~p"/admin/guests")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, "Please correct errors in inputs to continue!")
          |> assign(guest: to_form(changeset))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"action" => "edit", "guest" => guest_params}, socket) do
    guest = socket.assigns.guest_object

    case Clients.update_guest(guest, guest_params) do
      {:ok, guest} ->
        socket =
          socket
          |> put_flash(:info, "#{guest.name} #{guest.surname} updated successfully")
          |> push_patch(to: ~p"/admin/guests")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(guest: to_form(changeset, action: :validate))
          |> put_flash(:error, "Please correct errors in inputs to continue!")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"guest" => guest_params, "action" => "edit"} = params, socket) do
    guest = socket.assigns.guest_object
    guest_form = guest |> Guest.changeset(guest_params) |> to_form(action: :validate)

    socket =
      socket
      |> assign(guest: guest_form)

    {:noreply, socket}
  end

  def handle_event("validate", %{"guest" => guest_params, "action" => "new"} = _params, socket) do
    guest_form = %Guest{} |> Guest.changeset(guest_params) |> to_form(action: :validate)

    {:noreply, assign(socket, guest: guest_form)}
  end

  @impl true
  def handle_event("search", %{"query" => ""}, socket) do
    {:noreply, socket}
  end

  # Search by Document number
  @impl true
  def handle_event(
        "search",
        %{"query" => query, "type" => "doc_number"},
        socket
      ) do
    query = String.trim(query)

    if String.length(query) < 3 do
      {:noreply, socket}
    else
    end
  end

  #### Simple pagination events #####
  @impl true
  def handle_event("next-page", _unsigned_params, socket) do
    current_page = socket.assigns.current_page
    next_page = current_page + 1
    guests = Clients.get_guests(next_page)

    socket =
      socket
      |> assign(guests: guests)
      |> assign(current_page: next_page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("prev-page", _unsigned_params, socket) do
    current_page = socket.assigns.current_page
    prev_page = current_page - 1
    guests = Clients.get_guests(prev_page)

    socket =
      socket
      |> assign(guests: guests)
      |> assign(current_page: prev_page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("first-page", _unsigned_params, socket) do
    guests = Clients.get_guests(@first_page)

    socket =
      socket
      |> assign(guests: guests)
      |> assign(current_page: @first_page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("last-page", _unsigned_params, socket) do
    last_page = socket.assigns.no_of_pages - 1

    guests = Clients.get_guests(last_page)

    socket =
      socket
      |> assign(guests: guests)
      |> assign(current_page: last_page)

    {:noreply, socket}
  end

  ####################

  # Helper functions

  # applying live action from router with fields

  defp apply_live_action(_params, :index, socket) do
    guests = Clients.get_guests(@first_page)
    no_of_pages = Paginator.number_of_pages(Guest)

    socket
    |> assign(action: :index)
    |> assign(guests: guests)
    |> assign(no_of_pages: no_of_pages)
    |> assign(current_page: @first_page)
  end

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

  defp apply_live_action(%{"id" => id}, :edit, socket) do
    {form, guest} = guest_form(:edit, id)
    doc_types = Constants.doc_types()
    countries = Constants.all_countries()

    socket
    |> assign(doc_types: doc_types)
    |> assign(countries: countries)
    |> assign(title: "Guest data")
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
