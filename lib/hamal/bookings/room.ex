defmodule Hamal.Bookings.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:number, :no_of_beds, :price, :notes]
  @required_fields [:number, :no_of_beds, :price]

  schema "rooms" do
    field :number, :integer
    field :no_of_beds, :integer
    field :price, :integer
    field :notes, :string
    # Statuses: available, booked, occupied, under_maintenance, out_of_order
    # Statuses are set and updated by the hotel staff and in CSV form
    field :status, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(room, params \\ %{}) do
    room
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_number(:number, greater_than: 0)
    |> validate_number(:no_of_beds, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
  end

  def map_statuses(status) do
    case status do
      0 -> "available"
      1 -> "booked"
      2 -> "occupied"
      3 -> "under maintenance"
      4 -> "out of order"
      _ -> "unknown"
    end
  end
end
