now = DateTime.utc_now() |> DateTime.truncate(:second)
guests = Enum.map(1..10000, fn x -> %{name: "Hello#{x}", surname: "World#{x}", inserted_at: now, updated_at: now} end)
Hamal.Repo.insert_all(Hamal.Clients.Guest, guests)
