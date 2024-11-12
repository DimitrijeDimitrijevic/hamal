defmodule Hamal.Clients do
  alias Hamal.Clients.Guest
  alias Hamal.Repo
  import Ecto.Query

  def new_guest() do
    %Guest{}
    |> Guest.changeset()
  end

  def create_guest(params) do
    %Guest{}
    |> Guest.changeset(params)
    |> Repo.insert()
  end

  def get_guest(guest_id) do
    Repo.get_by(Guest, id: guest_id)
  end

  def get_guest(guest_name, guest_surname) do
    from(g in Guest, where: g.name == ^guest_name and g.surname == ^guest_surname, select: g.id)
    |> Repo.one()
  end

  def get_company(company_vat) do
    from(c in Company, where: c.vat == ^company_vat, select: c.id)
    |> Repo.one()
  end
end
