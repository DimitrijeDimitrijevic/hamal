defmodule Hamal.Repo.Migrations.AddRoomsTable do
  use Ecto.Migration

  def change do
    create table("rooms") do
      add :number, :integer
      add :no_of_beds, :integer
      add :price, :integer
      add :notes, :string
      add :status, :integer
      add :min_occupancy, :integer
      add :max_occupancy, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:number])
    create index(:rooms, [:id])
  end
end
