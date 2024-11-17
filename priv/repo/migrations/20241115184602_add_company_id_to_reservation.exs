defmodule Hamal.Repo.Migrations.AddCompanyIdToReservation do
  use Ecto.Migration

  def change do
    alter table("reservations") do
      add :company_id, references("companies", on_delete: :nothing)
      add :guest_id, references("guests", on_delete: :nothing)
    end
  end
end
