# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :waev, WaevWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "3Nj9X0/OrNnXhxVD+0HWwKCyGzEUsHrBSbnLNlX/y4SyVR934OWoIqs2+GYm993q",
  render_errors: [view: WaevWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Waev.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :waev, Waev.Export, exports_path: "./exports"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
