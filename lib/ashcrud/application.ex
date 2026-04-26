defmodule Ashcrud.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AshcrudWeb.Telemetry,
      Ashcrud.Repo,
      {DNSCluster, query: Application.get_env(:ashcrud, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ashcrud.PubSub},
      # Start a worker by calling: Ashcrud.Worker.start_link(arg)
      # {Ashcrud.Worker, arg},
      # Start to serve requests, typically the last entry
      AshcrudWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :ashcrud]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ashcrud.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshcrudWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
