defmodule Hamal.Paginator do
  alias Hamal.Repo
  import Ecto.Query
  @limit_per_page 15

  def number_of_pages(module) do
    module
    |> Repo.aggregate(:count, :id)
    |> Kernel./(@limit_per_page)
    |> ceil()
  end

  def paginate(module, page) do
    module
    |> paginate_query(page)
  end

  defp paginate_query(module, page) when page == 0 do
    from(m in module,
      order_by: [desc: m.inserted_at],
      limit: @limit_per_page,
      select: m
    )
  end

  defp paginate_query(module, page) when page >= 1 do
    from(m in module,
      order_by: [desc: m.inserted_at],
      limit: @limit_per_page,
      offset: ^page * @limit_per_page,
      select: m
    )
  end
end
