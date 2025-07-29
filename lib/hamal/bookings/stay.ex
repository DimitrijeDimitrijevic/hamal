defmodule Hamal.Bookings.Stay do
  use Ecto.Schema
  import Ecto.Changeset

  @permitted [
    :checked_in,
    :checked_out
  ]

  schema "stays" do
    belongs_to :reservation, Hamal.Bookings.Reservation
    belongs_to :guest, Hamal.Clients.Guest
    belongs_to :room, Hamal.Bookings.Room
    field :checked_in, :utc_datetime
    field :checked_out, :utc_datetime
    timestamps(type: :utc_datetime)
  end

  def changeset(stay, params \\ %{}) do
    stay
    |> cast(params, @permitted)
  end

  def add_room_and_guest(stay, room, guest) do
    stay
    |> cast(%{}, @permitted)
    |> put_assoc(:room, room)
    |> put_assoc(:guest, guest)
    |> put_change(:checked_in, DateTime.truncate(DateTime.utc_now(), :second))
  end

  def check_out_changeset(stay) do
    cast(stay, %{}, @permitted)
    |> put_change(:checked_out, DateTime.truncate(DateTime.utc_now(), :second))
  end
end
