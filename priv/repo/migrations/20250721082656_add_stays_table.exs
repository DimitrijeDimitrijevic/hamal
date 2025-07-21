defmodule Hamal.Repo.Migrations.AddStaysTable do
  use Ecto.Migration

  def change do
    create table(:stays) do
      add :guest_id, references("guests", on_delete: :nothing)
      add :reservation_id, references("reservations", on_delete: :nothing)
      add :room_id, references("rooms", on_delete: :nothing)
      add :checked_in, :utc_datetime
      add :checked_out, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:stays, [:reservation_id])
    create index(:stays, [:id])
    create index(:stays, [:room_id])
    create index(:stays, [:guest_id])
    create index(:stays, [:guest_id, :reservation_id, :room_id])
    create index(:stays, [:checked_in, :checked_out])
  end
end
