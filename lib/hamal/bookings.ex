defmodule Hamal.Bookings do
  import Ecto.Query
  alias Hamal.Repo
  alias Hamal.Bookings.{Reservation, Room}

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

  def new_reservation() do
    %Reservation{}
    |> Reservation.new_changeset()
  end

  def create_reservation(params) do
    %Reservation{}
    |> Reservation.changeset(params)
    |> Repo.insert()
  end
end
