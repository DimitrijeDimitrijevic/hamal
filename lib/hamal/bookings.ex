defmodule Hamal.Bookings do
  import Ecto.Query
  alias Hamal.Repo
  alias Hamal.Bookings.{Reservation, Room, Stay}
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

  def get_room(room_id) do
    Repo.get_by(Room, id: room_id)
  end

  # @doc """
  # All rooms which are not under maintenance or out of order
  # """
  # def get_reservable_rooms(check_in, check_out) do
  #   booked_rooms_ids = get_booked_rooms_for_period(check_in, check_out)
  #   availabe_rooms = available_rooms_query() |> Repo.all()

  #   Enum.filter(availabe_rooms, fn room ->
  #     room.id not in booked_rooms_ids
  #   end)
  # end
  #

  def search_reservations(params) do
    dynamic_query = construct_reservation_query(params)

    Hamal.Bookings.Reservation
    |> where(^dynamic_query)
    |> order_by([res], desc: res.check_in)
    |> preload([res], :rooms)
    |> Repo.all()
  end

  defp construct_reservation_query(params) do
    condition = true

    Enum.reduce(params, condition, fn
      {"guest_name", value}, condition when value != "" ->
        dynamic([res], ^condition and res.guest_name == ^value)

      {"guest_surname", value}, condition when value != "" ->
        dynamic([res], ^condition and res.guest_surname == ^value)

      {"check_in_date", value}, condition when value != "" ->
        dynamic([res], ^condition and res.check_in == ^value)

      {_, _}, condition ->
        condition
    end)
  end

  def reservable_rooms_for_period(check_in, check_out) do
    booked_rooms_ids = booked_rooms_ids(check_in, check_out)

    rooms_available_for_reservation()
    |> Enum.filter(fn room ->
      room.id not in booked_rooms_ids
    end)
  end

  # This is query for get all rooms which are not
  # - out of order 1
  # - under maintanance 2
  # TODO: this should be expanded to handle also table for tracking room cleaning
  defp available_rooms_query() do
    from(room in Room,
      where: room.status == 0,
      select: room
    )
  end

  def rooms_available_for_reservation() do
    available_rooms_query() |> Repo.all()
  end

  @doc """
  Function for getting reserved rooms for period
  of time, check in and check out
  """
  def get_reserved_rooms_for_period(check_in, check_out) do
    from(reservation in Hamal.Bookings.Reservation,
      where: reservation.check_in <= ^check_in and reservation.check_out >= ^check_out,
      select: reservation,
      preload: [:rooms]
    )
    |> Repo.all()
    |> Stream.flat_map(fn reservation -> reservation.rooms end)
    |> Enum.to_list()
  end

  defp booked_rooms_ids(check_in, check_out) do
    get_reserved_rooms_for_period(check_in, check_out)
    |> Stream.map(& &1.id)
    |> Enum.uniq()
  end

  def new_reservation(params \\ %{}) do
    %Reservation{}
    |> Reservation.new_changeset(params)
  end

  def get_all_reservations() do
    Reservation
    |> order_by([r], asc: r.check_in)
    |> Repo.all()
    |> Repo.preload(:rooms)
  end

  def get_reservation(reservation_id) do
    Reservation
    |> Repo.get(reservation_id)
    |> Repo.preload(:rooms)
  end

  def create_reservation(params, room_ids, guest) do
    result =
      new_reservation_multi(params, room_ids, guest)
      |> Repo.transaction()

    case result do
      {:ok, %{reservation: reservation}} ->
        reservation = Repo.preload(reservation, :rooms)
        confirmation_email = Hamal.Emails.Bookings.confirmation_email(reservation)
        Hamal.Mailer.deliver(confirmation_email)
        {:ok, reservation}

      {:error, operation, changeset, _changes} ->
        case operation do
          :new_reservation -> {:error, changeset}
          :reservation -> {:error, changeset}
          _ -> {:error, :other_failure}
        end
    end
  end

  defp new_reservation_multi(reservation_params, rooms_ids, guest) do
    # First we create reservation, then we check guest and company existance, then we create then if they do not exists
    # Afterwards we update the reservation with company_id and guest_id if they are present or created.
    # This will make life easier in future!
    Ecto.Multi.new()
    |> Ecto.Multi.all(:rooms, get_rooms_by_ids(rooms_ids))
    |> Ecto.Multi.insert(:new_reservation, fn %{rooms: rooms} ->
      Reservation.create_changeset(%Reservation{}, rooms, reservation_params)
    end)
    |> Ecto.Multi.run(:guest, fn _repo, %{new_reservation: reservation} ->
      if is_nil(guest) do
        guest_params = %{
          name: reservation.guest_name,
          surname: reservation.guest_surname,
          email: reservation.contact_email,
          phone: reservation.contact_number
        }

        Clients.create_guest(
          guest_params,
          :reservation
        )
      else
        {:ok, guest}
      end
    end)
    |> Ecto.Multi.run(:company, fn _repo, %{new_reservation: reservation} ->
      {action, company} =
        Clients.get_company_by_vat_and_name(reservation.company_vat, reservation.company_name)

      if action == nil do
        {:ok, nil}
      else
        if is_nil(company) do
          Clients.create_company(%{name: reservation.company_name, vat: reservation.company_vat},
            from: :reservation
          )
        else
          {:ok, company}
        end
      end
    end)
    |> Ecto.Multi.update(:reservation, fn %{
                                            company: company,
                                            guest: guest,
                                            new_reservation: reservation
                                          } ->
      reservation
      |> Ecto.Changeset.change(%{guest_id: guest.id, company_id: company && company.id})
    end)
  end

  # This will need to handle more cases.
  # like changing guest, company, other fields will be ok
  def update_reservation(reservation_id, params, room_ids) do
    reservation = get_reservation(reservation_id)
    rooms = get_rooms_by_ids(room_ids) |> Repo.all()

    Reservation.update_changeset(reservation, rooms, params)
    |> Repo.update()
  end

  def search_reservations_by_id(reservation_id) do
    from(reservation in Reservation,
      where: reservation.id == ^reservation_id,
      select: reservation
    )
    |> Repo.all()
    |> Repo.preload(:rooms)
  end

  def get_rooms_by_ids(room_ids) do
    from(r in Room, where: r.id in ^room_ids, select: r)
  end

  ### Stays
  def new_stay(params \\ %{}) do
    %Stay{}
    |> Stay.changeset(params)
  end

  def check_in_guest(reservation, room, %Guest{} = guest) do
    result =
      Ecto.build_assoc(reservation, :stays)
      |> Stay.add_room_and_guest(room, guest)
      |> Hamal.Repo.insert()

    case result do
      {:ok, stay} ->
        {:ok, stay, guest}

      {:error, changeset} ->
        {:error, guest}
    end
  end

  def check_in_guest(reservation, room, guest) when is_map(guest) do
    guest_changeset = Guest.check_in_changeset(%Guest{}, guest)

    case Repo.insert(guest_changeset) do
      {:ok, guest} ->
        stay_result =
          Ecto.build_assoc(reservation, :stays)
          |> Stay.add_room_and_guest(room, guest)
          |> Repo.insert()

        case stay_result do
          {:ok, stay} ->
            {:ok, stay, guest}

          _ ->
            {:error, nil}
        end

      {:error, _guest_changeset} = result ->
        result
    end
  end

  def get_stay_by_id(stay_id) do
    Repo.get_by(Stay, id: stay_id)
  end

  def current_guests_in_room_count(room_id, reservation) do
    reservation = Repo.preload(reservation, :stays)

    Enum.count(reservation.stays, fn stay -> stay.room_id == room_id end)
  end

  def all_stays(date) do
    from(s in Stay,
      where: type(s.checked_in, :date) <= ^date and is_nil(s.checked_out),
      select: s
    )
    |> Repo.all()
    |> Repo.preload([:reservation, :room, :guest])
  end

  def all_stays() do
    Repo.all(Stay)
    |> Repo.preload([:reservation, :room, :guest])
  end

  def check_out_stay(stay) do
    stay
    |> Stay.check_out_changeset()
    |> Repo.update()
  end

  ## GEt only relevant stays for a room and for reservation
  ## stay.room_id in room_ids as list and stay_id.reservation_id == reservation.id
end
