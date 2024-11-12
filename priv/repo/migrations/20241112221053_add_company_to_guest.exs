defmodule Hamal.Repo.Migrations.AddCompanyToGuest do
  use Ecto.Migration

  def change do
    alter table("guests") do
      add :company_id, references("companies", on_delete: :nothing)
    end
  end
end
