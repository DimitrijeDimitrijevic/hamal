defmodule Hamal.Clients.Guest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hamal.Helpers.Constants, as: Constants
  alias Hamal.Helpers.Changeset

  @doc_types Constants.doc_types()

  @fields [
    :name,
    :surname,
    :email,
    :phone,
    :address,
    :city,
    :country,
    :notes,
    :document_number,
    :document_type,
    :birth_date
  ]

  @required_fields [
    :name,
    :surname,
    :address,
    :city,
    :country,
    :document_number,
    :document_type,
    :birth_date
  ]

  schema "guests" do
    field :name, :string
    field :surname, :string
    field :email, :string
    field :phone, :string
    field :address, :string
    field :city, :string
    field :country, :string
    field :notes, :string
    field :document_number, :string
    field :document_type, :string
    field :birth_date, :date
    belongs_to :company, Hamal.Clients.Company
    has_many :reservations, Hamal.Bookings.Reservation
    has_many :stay, Hamal.Bookings.Stay

    timestamps(type: :utc_datetime)
  end

  def changeset(guest, params \\ %{}) do
    guest
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    # |> validate_format(:phone, ~r/\d{9,}/)
    |> validate_inclusion(:document_type, @doc_types)
  end

  def changeset_from_reservation(guest, params \\ %{}) do
    guest
    |> cast(params, [:name, :surname, :phone, :email])
    |> Changeset.normalize_name(:name)
    |> Changeset.normalize_name(:surname)
  end

  def check_in_changeset(guest, params \\ %{}) do
    guest
    |> cast(params, @fields)
    |> validate_required([:phone, :email, :name, :surname, :document_type, :document_number])
  end
end
