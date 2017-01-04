defmodule FileService do
  use Application
  alias Poison, as: JSON

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(FileService.Repo, []),
      # Start the endpoint when the application starts
      supervisor(FileService.Endpoint, []),
      # Start your own worker by calling: FileService.Worker.start_link(arg1, arg2, arg3)
      # worker(FileService.Worker, [arg1, arg2, arg3]),
    ]

    # Delete all existing files.
    File.rm_rf("files/")
    File.mkdir("files/")

    # Register this file service with the Directory Service.
    hostname = "http://" <> Application.get_env(:file_service, FileService.Endpoint)[:url][:host] <> ":#{System.get_env("PORT")}"
    register_data = Base.url_encode64(JSON.encode!(%{secret_code: "secret_register_password", server: hostname}))
    {:ok, response} = HTTPoison.post "#{Application.get_env(:file_service, FileService.Endpoint)[:directory_service_host]}/register", "{\"data\": \"" <> register_data <> "\"}", [{"Content-Type", "application/json"}]
    IO.inspect JSON.decode!(Base.url_decode64!((String.trim(response.body, "\""))))

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FileService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FileService.Endpoint.config_change(changed, removed)
    :ok
  end
end
