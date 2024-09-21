defmodule Hamal.Repo.Migrations.AddReservationsTable do
  use Ecto.Migration

  def change do
    create table("reservations") do
      add :guest_id, references("guests", on_delete: :delete_all), null: false
      add :check_in, :utc_datetime, null: false
      add :check_out, :utc_datetime, null: false
      add :status, :string
      add :notes, :string

      timestamps(type: :utc_datetime)
    end
  end
end
