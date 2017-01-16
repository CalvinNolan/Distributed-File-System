defmodule LockService do
  use Application
  alias Poison, as: JSON

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

     # Tell the registry service our current hostname.
    hostname = "http://" <> Application.get_env(:lock_service, LockService.Endpoint)[:url][:host] <> ":#{Application.get_env(:lock_service, LockService.Endpoint)[:http][:port]}"
    registry_data = Base.url_encode64(JSON.encode!(%{service: "lock", hostname: hostname}))
    HTTPoison.post "#{Application.get_env(:lock_service, LockService.Endpoint)[:registry_service_host]}/register", "{\"data\": \"" <> registry_data <> "\"}", [{"Content-Type", "application/json"}]

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(LockService.Repo, []),
      # Start the endpoint when the application starts
      supervisor(LockService.Endpoint, []),
      # Start your own worker by calling: LockService.Worker.start_link(arg1, arg2, arg3)
      # worker(LockService.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LockService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LockService.Endpoint.config_change(changed, removed)
    :ok
  end
end
