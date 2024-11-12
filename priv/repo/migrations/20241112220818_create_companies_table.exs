defmodule Hamal.Repo.Migrations.CreateCompaniesTable do
  use Ecto.Migration

  def change do
    create table("companies") do
      add :name, :string
      add :vat, :string
      add :mat_no, :string
      add :address, :string
      add :city, :string
      add :country, :string
      add :phone, :string
      add :email, :string
      add :notes, :string
      add :discount, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index("companies", [:vat])
    create unique_index("companies", [:name, :vat])
    create index("companies", [:name])
  end
end
