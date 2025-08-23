defmodule Hamal.Helpers.Formatting do
  def date(%Date{} = date) do
    Timex.format!(date, "%d.%m.%Y", :strftime)
  end

  def yes_or_no(false), do: "No"
  def yes_or_no(true), do: "Yes"
end
