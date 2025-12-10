defmodule HamalWeb.Admin.CheckInLive do
  use HamalWeb, :live_view
  alias Hamal.Bookings
  alias Hamal.Clients.Guest
  alias Hamal.Clients

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <p>Hello World</p>
    """
  end
end
