# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :directory_service,
  ecto_repos: [DirectoryService.Repo]

# Configures the endpoint
config :directory_service, DirectoryService.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "WCk6NTObZT3A/ROYUp0bVwvjVUMor9JL3v6bnRkVmpUjE2+7CUcOFhrhBtHrmxYW",
  render_errors: [view: DirectoryService.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DirectoryService.PubSub, adapter: Phoenix.PubSub.PG2],
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
