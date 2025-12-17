defmodule Hamal.Bookings.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @min_room_price 1000

  @permitted [:number, :no_of_beds, :price, :notes, :min_occupancy, :max_occupancy]
  @required [:number, :no_of_beds, :price, :min_occupancy, :max_occupancy]

  schema "rooms" do
    field :number, :integer
    field :no_of_beds, :integer
    field :price, :integer
    field :notes, :string
    field :status, :integer, default: 0
    field :min_occupancy, :integer, default: 1
    field :max_occupancy, :integer
    many_to_many :reservations, Hamal.Bookings.Reservation, join_through: "reservations_rooms"
    has_many :stays, Hamal.Bookings.Stay

    timestamps(type: :utc_datetime)
  end

  def changeset(room, params \\ %{}) do
    room
    |> cast(params, @permitted)
    |> validate_required(@required)
    |> validate_number(:price, greater_than_or_equal_to: @min_room_price)
    # this also requires unique_index in migration
    |> unique_constraint([:number])
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
