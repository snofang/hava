import Config

config :hava, Inspector,
  # in milliseconds
  interval: 1_000,
  enabled: false

config :hava, Compensator, enabled: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
