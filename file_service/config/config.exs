# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :file_service,
  ecto_repos: [FileService.Repo]

# Configures the endpoint
config :file_service, FileService.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cWLN0/k6xKPFjEtvzjE/2NokzyOS+GY5Ba+3in6eGsEan/Js7kdU9C6zCmxfYhbz",
  render_errors: [view: FileService.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FileService.PubSub, adapter: Phoenix.PubSub.PG2],
  directory_service_host: "http://localhost:3040",
  client_service_host: "http://localhost:3010",
  registry_service_host: "http://localhost:3000",
  security_service_host: "http://localhost:3020"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
