defmodule Hamal.Helpers.Changeset do
  import Ecto.Changeset

  def normalize_name(ch, field) do
    value = get_field(ch, field, nil)

    if is_nil(value) do
      ch
    else
      value =
        value
        |> String.trim()
        |> String.downcase()
        |> String.capitalize()

      put_change(ch, field, value)
    end
  end

  def trim_string(ch, field) do
    val = get_field(ch, field, nil)

    if is_nil(val) do
      ch
    else
      val = val |> String.trim() |> String.downcase()

      put_change(ch, field, val)
    end
  end
end
