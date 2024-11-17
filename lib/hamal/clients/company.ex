defmodule Hamal.Clients.Company do
  use Ecto.Schema
  import Ecto.Changeset

  @permitted [
    :name,
    :vat,
    :mat_no,
    :address,
    :city,
    :country,
    :phone,
    :email,
    :notes
  ]

  @required [:name]

  schema "companies" do
    field :name, :string
    field :vat, :string
    field :mat_no, :string
    field :address, :string
    field :city, :string
    field :country, :string
    field :phone, :string
    field :email, :string
    field :notes, :string
    # Discount for company in percentage
    field :discount, :integer, default: 0
    has_many :guests, Hamal.Clients.Guest

    timestamps(type: :utc_datetime)
  end

  def changeset(company, params \\ %{}) do
    company
    |> cast(params, @permitted)
    |> validate_required(@required)
  end

  def changeset_from_reservation(company, params \\ %{}) do
    company
    |> cast(params, @permitted)
    |> validate_required([:name])
  end
end
