defmodule Hamal.Emails.Bookings do
  @moduledoc """
  Email messages which are for reservations.
  """
  import Swoosh.Email

  def confirmation_email(reservation) do
    text = "Hello world"

    new()
    |> to(reservation.contact_email)
    |> from("reservations@hotelaloha.rs")
    |> text_body(text)
  end
end
