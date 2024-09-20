defmodule HamalWeb.Admin.HomeController do
  use HamalWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Hello World")
    |> render(:index)
  end
end
