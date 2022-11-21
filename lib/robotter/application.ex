defmodule Robotter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      RobotterWeb.Telemetry,
      # Start the Ecto repository
      Robotter.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Robotter.PubSub},
      # Start Finch
      {Finch, name: Robotter.Finch},
      # Start the Endpoint (http/https)
      RobotterWeb.Endpoint
      # Start a worker by calling: Robotter.Worker.start_link(arg)
      # {Robotter.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Robotter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RobotterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
