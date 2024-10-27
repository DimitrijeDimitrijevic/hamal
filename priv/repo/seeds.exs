# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hamal.Repo.insert!(%Hamal.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Create few rooms to have always in dev phase.
rooms_count = 3

Enum.each(1..rooms_count, fn n ->
  Hamal.Bookings.create_room!(%{
    number: 100 + n,
    no_of_beds: n,
    price: 1000 + n * 100
  })
end)
