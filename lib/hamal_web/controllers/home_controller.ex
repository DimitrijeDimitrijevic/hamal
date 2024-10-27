defmodule HamalWeb.HomeController do
  use HamalWeb, :controller

  def index(conn, _) do
    json(conn, %{page: "This page does not have auth! FIX IT!!!"})
  end
end
