defmodule Hamal.Repo.Migrations.AddReservationsRoomsTable do
  use Ecto.Migration

  def change do
    create table("reservations_rooms") do
      add :room_id, references("rooms", on_delete: :nothing)
      add :reservation_id, references("reservations", on_delete: :nothing)
    end
    end
end
