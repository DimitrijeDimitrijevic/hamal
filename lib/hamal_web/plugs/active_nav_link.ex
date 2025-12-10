defmodule HamalWeb.Plugs.ActiveNavLink do
  @moduledoc """
  This module unlike the similar one is taking care of active link when
  traditional non-live page is rendered
  """
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    path_info = conn.path_info

    active_item =
      if admin_or_user(path_info) in [:admin, :user] do
        :home
      else
        [_admin_or_user, current_path | _rest] = path_info

        case current_path do
          "users" ->
            :users

          "rooms" ->
            :rooms

          _ ->
            nil
        end
      end

    assign(conn, :active_item, active_item)
  end

  # Lets determine if we are in user or admin section
  defp admin_or_user(["admin"]), do: :admin
  defp admin_or_user([]), do: :user
  defp admin_or_user([_value | _rest]), do: :other
end
