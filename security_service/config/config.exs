# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :security_service,
  ecto_repos: [SecurityService.Repo]

# Configures the endpoint
config :security_service, SecurityService.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "33MIilcObv/xCQqgEtfW1xXO4uQAtgbdWpxQD13eh9gNqGPJvNwzPL1/3a7rHx3m",
  render_errors: [view: SecurityService.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SecurityService.PubSub, adapter: Phoenix.PubSub.PG2],
  client_service_host: "http://localhost:3010",
  registry_service_host: "http://localhost:3000"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
