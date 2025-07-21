defmodule HamalWeb.Admin.HomeController do
  use HamalWeb, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end
end
