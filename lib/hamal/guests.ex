defmodule Hamal.Guests do
  alias Hamal.Guests.Guest
  alias Hamal.Repo

  def new_guest() do
    %Guest{}
    |> Guest.changeset()
  end

  def create_guest(%Guest{} = guest) do
    guest
    |> Guest.changeset()
    |> Repo.insert()
  end
end
