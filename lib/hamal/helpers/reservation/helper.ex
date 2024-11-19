defmodule Hamal.Helpers.Reservation.Helper do
  @moduledoc """
  Helper functions for Reservation live view
  """

  def check_in_check_out_to_dates(check_in, nil) do
    {:ok, check_in} = Date.from_iso8601(check_in)
    {check_in, nil}
  end

  def check_in_check_out_to_dates(check_in, check_out) do
    {:ok, check_in} = Date.from_iso8601(check_in)
    {:ok, check_out} = Date.from_iso8601(check_out)

    {check_in, check_out}
  end
end
