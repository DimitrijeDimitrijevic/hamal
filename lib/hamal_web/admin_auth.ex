defmodule HamalWeb.AdminAuth do
  @moduledoc """
  Regular plug for basic auth.
  Username and password comes from ENV on server!
  """
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    username = Application.fetch_env!(:hamal, :basic_auth)[:username]
    password = Application.fetch_env!(:hamal, :basic_auth)[:password]
    realm = Application.fetch_env!(:hamal, :basic_auth)[:realm]
    Plug.BasicAuth.basic_auth(conn, username: username, password: password, realm: realm)
  end
end
