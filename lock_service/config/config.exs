# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :lock_service,
  ecto_repos: [LockService.Repo]

# Configures the endpoint
config :lock_service, LockService.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "diqnCt9WdJilgKX0K60AfAzk2A2B6G6i2dKUp1D5ayJBQa5MCJQP/YaHSi8Cej/L",
  render_errors: [view: LockService.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LockService.PubSub,
           adapter: Phoenix.PubSub.PG2],
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
