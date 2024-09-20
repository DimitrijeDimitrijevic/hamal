defmodule Hamal.Repo.Migrations.AddRoomsTable do
  use Ecto.Migration

  def change do
    create table("rooms") do
      add :number, :integer
      add :no_of_beds, :integer
      add :price, :integer
      add :notes, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end

    create index("rooms", [:number])
  end
end
