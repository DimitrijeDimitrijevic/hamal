defmodule Hamal.Helpers.Formatting do
  def date(%Date{} = date) do
    Timex.format!(date, "%d.%m.%Y", :strftime)
  end
end
