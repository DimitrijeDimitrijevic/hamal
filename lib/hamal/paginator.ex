defmodule Hamal.Paginator do
  alias Hamal.Repo
  @limit_per_page 50

  def number_of_pages(module) do
    module
    |> Repo.aggregate(:count, :id)
    |> Kernel./(@limit_per_page)
    |> ceil()
  end
end
