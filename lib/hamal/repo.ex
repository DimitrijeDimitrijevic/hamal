defmodule Hamal.Repo do
  use Ecto.Repo,
    otp_app: :hamal,
    adapter: Ecto.Adapters.Postgres
end
