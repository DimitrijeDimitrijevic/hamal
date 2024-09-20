defmodule HamalWeb.Admin.RoomHTML do
  use HamalWeb, :html

  embed_templates "room_html/*"

  def room_statuses() do
    [
      {"available", 0},
      {"booked", 1},
      {"occupied", 2},
      {"under maintanance", 3},
      {"out of order", 4}
    ]
  end
end
