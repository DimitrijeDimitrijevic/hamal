defmodule Hamal.Repo.Migrations.AddReservationsTable do
  use Ecto.Migration

  def change do
    create table("reservations") do
      add :check_in, :date, null: false
      add :check_out, :date, null: false
      add :guaranteed, :boolean
      add :guest_name, :string
      add :guest_surname, :string
      add :contact_number, :string
      add :contact_email, :string
      add :company_name, :string
      add :breakfast, :boolean
      add :notes, :text
      add :user_id, :integer
      add :channel, :string

      timestamps(type: :utc_datetime)
    end

    # Indexes for searching by check_in, check_out and both
    create index(:reservations, [:check_in])
    create index(:reservations, [:check_out])
    create index(:reservations, [:check_in, :check_out])
  end
end
