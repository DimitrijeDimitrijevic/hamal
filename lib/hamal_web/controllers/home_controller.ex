defmodule HamalWeb.HomeController do
  use HamalWeb, :controller

  def index(conn, _) do
    current_user = conn.assigns.current_user
    dbg(current_user)
    render(conn, :index)
  end
end
