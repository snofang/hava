import Config

config :hava, Inspector,
  # in milliseconds
  interval: 20_000,
  # net intefrace as the source of usage data
  usage_interface: "wlp3s0",
  enabled: true

config :hava, Compensator,
  initial_speed: 80,
  recap_ratio: 1,
  enabled: true

config :hava, :run_pick,
  max_call_gap: 10_000,
  max_call_duration: 10_000,
  min_send_ratio: 10

config :hava, Uploader,
  # enable/disable real upload
  enabled: true

config :hava, :cmd_wrapper, Hava.CmdWrapperImpl
config :hava, :uploader, Hava.UploaderLibreSt
config :hava, :stats, Hava.StatsDev
config :hava, :http_client, HTTPoison

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
