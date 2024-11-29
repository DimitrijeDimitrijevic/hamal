defmodule Hamal.Clients do
  alias Hamal.Clients.{Guest, Company}
  alias Hamal.Repo
  import Ecto.Query

  def new_guest() do
    %Guest{}
    |> Guest.changeset()
  end

  def create_guest(params, :reservation) do
    %Guest{}
    |> Guest.changeset_from_reservation(params)
    |> Repo.insert()
  end

  def create_guest(params, :guest) do
    %Guest{}
    |> Guest.changeset(params)
    |> Repo.insert()
  end

  def update_guest(guest, params) do
    guest
    |> Guest.changeset(params)
    |> Repo.update()
  end

  def get_all_guests(limit_per_page, page) do
    from(g in Guest,
      order_by: [desc: g.inserted_at],
      limit: ^limit_per_page,
      offset: (^page - 1) * ^limit_per_page,
      select: g
    )
    |> Repo.all()
  end

  def get_guest(guest_id) do
    Repo.get_by(Guest, id: guest_id)
  end

  def get_guest(guest_name, guest_surname) do
    from(g in Guest, where: g.name == ^guest_name and g.surname == ^guest_surname, select: g)
    |> Repo.one()
  end

  def get_company_by_vat(company_vat) do
    from(c in Company, where: c.vat == ^company_vat, select: c.id)
    |> Repo.one()
  end

  def get_company_by_name(company_name) do
    from(c in Company, where: c.name == ^company_name, select: c.id)
    |> Repo.one()
  end

  def get_company_by_vat_and_name(company_vat, company_name)
  def get_company_by_vat_and_name(nil, company_name), do: get_company_by_name(company_name)
  def get_company_by_vat_and_name(company_vat, nil), do: get_company_by_vat(company_vat)
  def get_company_by_vat_and_name(nil, nil), do: nil

  def get_company_by_vat_and_name(company_vat, company_name) do
    from(c in Company, where: c.vat == ^company_vat and c.name == ^company_name, select: c)
    |> Repo.one()
  end

  def create_company(params, opts \\ []) do
    changeset =
      case Keyword.get(opts, :from, :company) do
        :reservation ->
          %Company{}
          |> Company.changeset_from_reservation(params)

        :company ->
          %Company{}
          |> Company.changeset(params)

        _ ->
          %Company{}
          |> Company.changeset(params)
      end

    Repo.insert(changeset)
  end
end
