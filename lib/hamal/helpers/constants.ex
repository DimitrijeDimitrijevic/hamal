defmodule Hamal.Helpers.Constants do
  alias Hamal.Helpers.Cldr, as: CldrHelper
  def hotel_name, do: "hotelaloha"

  def doc_types, do: ["passport", "id", "other"]

  def all_countries() do
    CldrHelper.generate_countries_list()
  end

  def reservation_channel_types do
    ["walk-in", "booking", "phone", "email", "website"]
  end
end
