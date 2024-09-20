defmodule Hamal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HamalWeb.Telemetry,
      Hamal.Repo,
      {DNSCluster, query: Application.get_env(:hamal, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Hamal.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Hamal.Finch},
      # Start a worker by calling: Hamal.Worker.start_link(arg)
      # {Hamal.Worker, arg},
      # Start to serve requests, typically the last entry
      HamalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hamal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HamalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
