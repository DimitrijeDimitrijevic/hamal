defmodule Hamal.Bookings.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hamal.Bookings.Room

  @permitted [
    :check_in,
    :check_out,
    :guaranteed,
    :guest_name,
    :guest_surname,
    :company_name,
    :breakfast,
    :notes,
    :user_id,
    :channel,
    :contact_number,
    :contact_email,
    :company_name
  ]
  @required [:check_in, :check_out, :guest_name, :guest_surname, :contact_number, :contact_email]

  schema "reservations" do
    field :check_in, :date
    field :check_out, :date
    field :guaranteed, :boolean, default: false
    field :guest_name, :string
    field :guest_surname, :string
    field :contact_number, :string
    field :contact_email, :string
    field :company_name, :string
    field :breakfast, :boolean, default: false
    field :notes, :string
    # Which user created this reservation, nil if created by admin
    field :user_id, :integer, default: nil
    # From which channel reservation was made
    # We will set predefined values for channels such as
    # [Walk-in, Booking, Phone, Email, Website, Click & Book, Other]
    field :channel, :string

    # Relationship to rooms, trough join table on database level
    many_to_many :rooms, Hamal.Bookings.Room,
      join_through: "reservations_rooms",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  # This changeset will use only for validation,
  # as we use cast_assoc, which is just way to have delete and add on form, this is done now
  # on server side, but actually this should be client side issue with some form of JS.
  # Also we will use this when editing the reservation
  def validation_changeset(reservation, params \\ %{}) do
    reservation
    |> cast(params, @permitted)
    |> validate_required(@required)
    |> cast_assoc(:rooms,
      sort_param: :room_order,
      drop_param: :room_delete
    )
  end

  # on new we do not have any rooms present in reservation
  def new_changeset(reservation, params \\ %{}) do
    reservation
    |> cast(params, @permitted)
    |> assing_empty_rooms_list()
  end

  defp assing_empty_rooms_list(%Ecto.Changeset{} = changeset) do
    rooms = [%Room{}]
    put_change(changeset, :rooms, rooms)
  end
end
