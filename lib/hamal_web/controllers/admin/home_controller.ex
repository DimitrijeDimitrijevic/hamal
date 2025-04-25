defmodule HamalWeb.Admin.HomeController do
  use HamalWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "HELLO WORLD")
    |> render(:index)
  end
end
