# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :og_preview,
  ecto_repos: [OgPreview.Repo]

config :og_preview_web,
  ecto_repos: [OgPreview.Repo],
  generators: [context_app: :og_preview, binary_id: true]

# Configures the endpoint
config :og_preview_web, OgPreviewWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: OgPreviewWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: OgPreview.PubSub,
  live_view: [signing_salt: "lLDQUUMG"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/og_preview_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
