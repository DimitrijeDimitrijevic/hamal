defmodule HamalWeb.Admin.RoomController do
  use HamalWeb, :controller
  alias Hamal.Bookings

  def index(conn, _) do
    rooms = Bookings.get_all_rooms()
    render(conn, :index, rooms: rooms)
  end

  def new(conn, _) do
    room_changeset = Bookings.new_room()
    render(conn, :new, room_changeset: room_changeset)
  end

  def create(conn, %{"room" => room_params}) do
    case Bookings.create_room(room_params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room #{room.number} created successfully!")
        |> redirect(to: ~p"/admin/rooms")

      {:error, room_changeset} ->
        IO.inspect(room_changeset)

        conn
        |> put_flash(:error, "Please correct errors in inputs to continue!")
        |> render(:new, room_changeset: room_changeset)
    end
  end
end
