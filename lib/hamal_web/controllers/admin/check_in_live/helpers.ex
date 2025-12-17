defmodule HamalWeb.Admin.CheckInLive.Helpers do
  alias Hamal.Bookings.Room

  def room_max_occupancy_reached?(selected_guests, %Room{max_occupancy: max_occupancy}) do
    Enum.count(selected_guests) > max_occupancy
  end
end
