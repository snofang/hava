import Config

config :hava, Inspector, enabled: true
config :hava, Compensator, enabled: true
config :hava, Uploader, enabled: false

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
