defmodule Malarkey.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MalarkeyWeb.Telemetry,
      Malarkey.Repo,
      {DNSCluster, query: Application.get_env(:malarkey, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Malarkey.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Malarkey.Finch},
      # Start a worker by calling: Malarkey.Worker.start_link(arg)
      # {Malarkey.Worker, arg},
      # Start to serve requests, typically the last entry
      MalarkeyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Malarkey.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MalarkeyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
