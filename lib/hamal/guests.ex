defmodule Hamal.Guests do
  alias Hamal.Guests.Guest
  alias Hamal.Repo

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
end
