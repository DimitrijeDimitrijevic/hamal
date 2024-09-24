defmodule Hamal.Helpers.Cldr do
  use Cldr,
    locales: ["en"],
    providers: [Cldr.Territory]

  def generate_countries_list() do
    Cldr.Territory.country_codes(as: :binary)
    |> Enum.map(fn code -> coutry_name(code) end)
  end

  defp coutry_name(code) do
    {:ok, country_name} = Cldr.Territory.display_name(code, locale: "en")
    String.trim(country_name)
  end

  defp country_flag(code) do
    {:ok, flag} = Cldr.Territory.to_unicode_flag(code)
    flag
  end
end
