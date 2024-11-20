defmodule Hamal.Bookings.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hamal.Bookings.Room
  alias Hamal.Helpers.Changeset

  @permitted [
    :check_in,
    :check_out,
    :guaranteed,
    :guest_name,
    :guest_surname,
    :company_name,
    :company_vat,
    :breakfast,
    :notes,
    :user_id,
    :channel,
    :contact_number,
    :contact_email,
    :company_name,
    :no_of_nights,
    :company_id
  ]
  @required [:check_in, :check_out, :guest_name, :guest_surname, :contact_number, :channel]

  schema "reservations" do
    field :check_in, :date
    field :check_out, :date
    field :guaranteed, :boolean, default: false
    field :guest_name, :string
    field :guest_surname, :string
    field :contact_number, :string
    field :contact_email, :string
    # Company should be optional
    # If values are present in field the company should be created
    field :company_name, :string
    field :company_vat, :string
    field :breakfast, :boolean, default: false
    field :notes, :string
    # Which user created this reservation, nil if created by admin
    field :user_id, :integer, default: nil
    # From which channel reservation was made
    # We will set predefined values for channels such as
    # [Walk-in, Booking, Phone, Email, Website, Click & Book, Other]
    field :channel, :string
    # How many nights guest will stay
    # can be a free form or calculated from check_in and check_out
    # but should be present in database
    field :no_of_nights, :integer

    ## TODO: Lets think about this
    belongs_to :company, Hamal.Clients.Company
    belongs_to :guest, Hamal.Clients.Guest

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
    |> IO.inspect()
    |> handle_number_of_nights()
  end

  def create_changeset(reservation, rooms, params \\ %{}) do
    reservation
    |> cast(params, @permitted)
    |> validate_required(@required)
    |> put_assoc(:rooms, rooms)
    |> Changeset.normalize_name(:guest_name)
    |> Changeset.normalize_name(:guest_surname)
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

  # Handling number of nights and checkout date based on user input
  # from form, it is dynamic, so changing number of nights will change check_out dates
  # and vice versa
  defp handle_number_of_nights(
         %{
           changes: %{
             check_in: current_check_in,
             check_out: current_check_out,
             no_of_nights: no_of_nights
           }
         } = cs
       ) do
    no_of_nights_diff = Date.diff(current_check_out, current_check_in)
    check_out = Date.shift(current_check_in, day: no_of_nights)

    no_of_nights = if no_of_nights_diff != no_of_nights, do: no_of_nights_diff, else: no_of_nights
    no_of_nights = if no_of_nights == 0, do: 1, else: no_of_nights

    cs
    |> put_change(:no_of_nights, no_of_nights)
    |> put_change(:check_out, check_out)
  end

  defp handle_number_of_nights(%{changes: %{check_in: check_in, check_out: check_out}} = cs) do
    no_of_nights =
      case Date.diff(check_out, check_in) do
        0 -> 1
        n_nights -> n_nights
      end

    put_change(cs, :no_of_nights, no_of_nights)
  end

  defp handle_number_of_nights(%{changes: %{check_in: check_in, no_of_nights: no_of_nights}} = cs) do
    check_out = Date.shift(check_in, day: no_of_nights)
    put_change(cs, :check_out, check_out)
  end

  defp handle_number_of_nights(changeset), do: changeset
end
