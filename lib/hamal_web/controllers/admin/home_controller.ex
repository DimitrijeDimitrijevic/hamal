defmodule HamalWeb.Admin.HomeController do
  use HamalWeb, :controller

  def index(conn, _params) do
    dbg(conn)

    conn
    |> render(:index)
  end
end
