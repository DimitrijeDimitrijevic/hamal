defmodule Hamal.Repo.Migrations.CreateGuestsTable do
  use Ecto.Migration

  def change do
    create table("guests") do
      add :name, :string
      add :surname, :string
      add :email, :string
      add :phone, :string
      add :address, :string
      add :city, :string
      add :country, :string
      add :notes, :string
      add :document_number, :string
      add :document_type, :string
      add :bitrh_date, :date

      timestamps(type: :utc_datetime)
    end
  end
end
