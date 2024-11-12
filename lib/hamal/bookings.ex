defmodule Hamal.Bookings do
  import Ecto.Query
  alias Hamal.Repo
  alias Hamal.Bookings.{Reservation, Room}
  alias Hamal.Clients
  alias Hamal.Clients.Guest

  def new_room() do
    %Room{}
    |> Room.changeset()
  end

  def create_room(params) do
    %Room{}
    |> Room.changeset(params)
    |> Repo.insert()
  end

  def create_room!(params) do
    %Room{}
    |> Room.changeset(params)
    |> Repo.insert!()
  end

  def get_all_rooms() do
    Repo.all(Room)
  end

  @doc """
  All rooms which are not under maintenance or out of order
  """
  def get_reservable_rooms do
    from(r in Room, where: r.status == 0, select: r)
    |> Repo.all()
  end

  def new_reservation() do
    %Reservation{}
    |> Reservation.new_changeset()
  end

  def create_reservation(params, room_ids) do
    rooms = get_rooms_by_ids(room_ids)
    guest = Clients.get_guest(params["guest_name"], params["guest_surname"])
    company = Clients.get_company(params["company_vat"])
  end

  defp reservation_multi(reservation_params, rooms, guest, company) do
    %Reservation{}
    |> Reservation.create_changeset(rooms, reservation_params)
    |> Repo.insert()
  end

  def get_rooms_by_ids(room_ids) do
    from(r in Room, where: r.id in ^room_ids, select: r)
    |> Repo.all()
  end
end
