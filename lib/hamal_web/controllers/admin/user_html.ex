defmodule HamalWeb.Admin.UserHTML do
  use HamalWeb, :html

  embed_templates "user_html/*"

  def role(1), do: "Receptionist"
  def role(2), do: "Housekeeping"
end
