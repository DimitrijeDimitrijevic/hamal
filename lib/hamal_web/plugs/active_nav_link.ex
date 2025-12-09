defmodule HamalWeb.Plugs.ActiveNavLink do
  @moduledoc """
  This module unlike the similar one is taking care of active link when
  traditional non-live page is rendered
  """
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    ["admin", current_path | _rest] = conn.path_info
    dbg(current_path)

    active_item =
      case current_path do
        "users" ->
          :users

        "rooms" ->
          :rooms

        _ ->
          nil
      end

    assign(conn, :active_item, active_item)
  end
end
