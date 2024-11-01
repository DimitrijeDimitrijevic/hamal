defmodule Hamal.Bookings.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @permitted [:number, :no_of_beds, :price, :notes]
  @required [:number, :no_of_beds, :price]

  schema "rooms" do
    field :number, :integer
    field :no_of_beds, :integer
    field :price, :integer
    field :notes, :string
    # Statuses: available, booked, occupied, under_maintenance, out_of_order
    # Statuses are set and updated by the hotel staff and in CSV form
    field :status, :integer, default: 0
    many_to_many :reservations, Hamal.Bookings.Reservation, join_through: "reservations_rooms"

    timestamps(type: :utc_datetime)
  end

  def changeset(room, params \\ %{}) do
    room
    |> cast(params, @permitted)
  end

  def map_statuses(status) do
    case status do
      0 -> "available"
      1 -> "under maintenance"
      2 -> "out of order"
      _ -> "unknown"
    end
  end
end
