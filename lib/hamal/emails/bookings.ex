defmodule Hamal.Emails.Bookings do
  @moduledoc """
  Email messages which are for reservations.
  """
  import Swoosh.Email
  alias Hamal.Bookings.Reservation

  def confirmation_email(%Reservation{
        guest_surname: surname,
        guest_name: name,
        id: reservation_id,
        check_in: check_in,
        check_out: check_out,
        contact_email: contact_email,
        rooms: rooms
      }) do
    guest_name = String.upcase(name)
    guest_surname = String.upcase(surname)
    rooms = Enum.map(rooms, fn room -> room.number end) |> Enum.join(", ")

    text = """
    Dear Mr/Mrs #{guest_name} #{guest_surname},

    Thank you for making reservation at Hotel Aloha.

    Your reservation number is #{reservation_id}, please show this at front-desk upon your arrival at the hotel.

    Check-in date: #{Date.to_iso8601(check_in)}
    Check-out date: #{Date.to_iso8601(check_out)}
    Rooms: #{rooms}


    Enjoy your stay at hotel Aloha.

    Best regards,
    Hotel Aloha
    """

    new()
    |> to(contact_email)
    |> from("reservations@hotelaloha.rs")
    |> text_body(text)
  end
end
