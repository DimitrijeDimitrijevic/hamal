defmodule HamalWeb.Admin.RoomHTML do
  use HamalWeb, :html

  embed_templates "room_html/*"

  def room_statuses() do
    [
      {"Available", 0},
      {"Under maintanance", 1},
      {"Out of order", 2}
    ]
  end

  def room_status(room_status), do: Hamal.Bookings.Room.map_statuses(room_status)
end
