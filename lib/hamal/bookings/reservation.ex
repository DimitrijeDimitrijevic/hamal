defmodule Hamal.Bookings.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hamal.Bookings.Room
  alias Hamal.Helpers.Changeset

  @max_number_of_nights 30

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
  @required [:check_in, :check_out, :guest_name, :guest_surname, :channel]

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

    belongs_to :company, Hamal.Clients.Company
    belongs_to :guest, Hamal.Clients.Guest

    # Relationship to rooms, trough join table on database level
    many_to_many :rooms, Hamal.Bookings.Room,
      join_through: "reservations_rooms",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end


  def create_changeset(reservation, rooms, params \\ %{}) do
    reservation
    |> cast(params, @permitted)
    |> validate_required(@required)
    |> put_assoc(:rooms, rooms)
    |> Changeset.normalize_name(:guest_name)
    |> Changeset.normalize_name(:guest_surname)
    |> handle_check_in_check_out_dates()
  end

  def changeset(reservation, params \\ %{}) do
    reservation
    |> cast(params, @permitted)
    |> validate_required(@required)
    |> validate_contact_info()
    |> cast_assoc(:rooms,
     sort_param: :room_order,
     drop_param: :room_delete
        )
    |> handle_number_of_nights()
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

  defp handle_check_in_check_out_dates(cs_map, today \\ Date.utc_today())

  defp handle_check_in_check_out_dates(cs, today) do
    check_in = get_field(cs, :check_in)
    check_out = get_field(cs, :check_out, today)

    check_in_past = Date.compare(check_in, today) == :lt
    check_out_past = Date.compare(check_out, today) == :lt

    cs =
      if check_in_past,
        do: add_error(cs, :check_in, "Check in date can not be in the past"),
        else: cs

    if check_out_past,
      do: add_error(cs, :check_out, "Check out date can not be in the past"),
      else: cs
  end




  defp handle_number_of_nights(%{changes: %{check_out: check_out}} = changeset) do
    check_in = get_field(changeset, :check_in)
    no_of_nights = Date.diff(check_out, check_in)

    if no_of_nights > @max_number_of_nights do
      changeset
      |> add_error(:check_out, "must be maximum #{@max_number_of_nights} days")
      |> put_change(:check_out, Date.shift(check_in, day: @max_number_of_nights))
      else
      put_change(changeset, :no_of_nights, no_of_nights)
    end
  end

  defp handle_number_of_nights(changeset), do: changeset


  defp validate_contact_info(changeset) do
    changeset
    |> validate_contact_email()
    |> validate_contact_phone()
  end

  defp validate_contact_email(changeset) do
    changeset
    |> validate_required(:contact_email)
    |> validate_format(:contact_email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:contact_email, max: 50)
  end

  defp validate_contact_phone(changeset) do
    changeset
    |> validate_required(:contact_number)
    # |> validate_format(:contact_phone, regex_expression)
    |> validate_length(:contact_number, max: 25)
  end
end
