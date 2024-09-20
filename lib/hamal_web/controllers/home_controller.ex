defmodule HamalWeb.HomeController do
  use HamalWeb, :controller

  def index(conn, _) do
    render(conn, :index)
  end
end
