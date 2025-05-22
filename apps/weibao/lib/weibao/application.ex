defmodule Weibao.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Weibao.Repo,
      {DNSCluster, query: Application.get_env(:weibao, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Weibao.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Weibao.Finch}
      # Start a worker by calling: Weibao.Worker.start_link(arg)
      # {Weibao.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Weibao.Supervisor)
  end
end
