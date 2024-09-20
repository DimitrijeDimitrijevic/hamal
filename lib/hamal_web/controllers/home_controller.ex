defmodule HamalWeb.HomeController do
  use HamalWeb, :controller

  def index(conn, _) do
    json(conn, %{response: "JSON response"})
  end
end
