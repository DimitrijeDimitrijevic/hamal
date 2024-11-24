defmodule Hamal.Bookings do
  import Ecto.Query
  alias Hamal.Repo
  alias Hamal.Bookings.{Reservation, Room}
  alias Hamal.Clients.{Guest, Company}
  alias Hamal.Clients

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

  def get_all_reservations() do
    Reservation
    |> order_by([r], asc: r.check_in)
    |> Repo.all()
    |> Repo.preload(:rooms)
  end

  def create_reservation(params, room_ids) do
    result =
      reservation_multi(params, room_ids)
      |> Repo.transaction()

    case result do
      {:ok, %{reservation: reservation}} ->
        {:ok, reservation}

      {:error, operation, changeset, changes} ->
        case operation do
          :reservation -> {:error, changeset}
          _ -> {:error, :other_failure}
        end
    end
  end

  defp reservation_multi(reservation_params, rooms_ids) do
    # First we create reservation, then we check guest and company existance, then we create then if they do not exists
    # Afterwards we update the reservation with company_id and guest_id if they are present or created.
    # This will make life easier in future
    Ecto.Multi.new()
    |> Ecto.Multi.all(:rooms, get_rooms_by_ids(rooms_ids))
    |> Ecto.Multi.insert(:new_reservation, fn %{rooms: rooms} ->
      Reservation.create_changeset(%Reservation{}, rooms, reservation_params)
    end)
    |> Ecto.Multi.run(:guest, fn _repo, %{new_reservation: reservation} ->
      guest = Clients.get_guest(reservation.guest_name, reservation.guest_surname)

      if is_nil(guest) do
        Clients.create_guest(
          %{name: reservation.guest_name, surname: reservation.guest_surname},
          :reservation
        )
      else
        {:ok, guest}
      end
    end)
    |> Ecto.Multi.run(:company, fn _repo, %{new_reservation: reservation} ->
      company =
        Clients.get_company_by_vat_and_name(reservation.company_vat, reservation.company_name)

      if is_nil(company) do
        Clients.create_company(%{name: reservation.company_name, vat: reservation.company_vat},
          from: :reservation
        )
      else
        {:ok, company}
      end
    end)
    |> Ecto.Multi.update(:reservation, fn %{
                                            company: company,
                                            guest: guest,
                                            new_reservation: reservation
                                          } ->
      Ecto.Changeset.cast(reservation, %{company_id: company.id, guest_id: guest.id}, [
        :company_id,
        :guest_id
      ])
    end)
    |> Ecto.Multi.inspect()
  end

  def get_rooms_by_ids(room_ids) do
    from(r in Room, where: r.id in ^room_ids, select: r)
  end
end
