defmodule HamalWeb.Admin.HomeController do
  use HamalWeb, :controller
  alias Hamal.Bookings

  def index(conn, _params) do
    conn
    |> render(:index)
  end
end
