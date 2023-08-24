import Config

config :hava, Inspector, enabled: false
config :hava, Compensator, enabled: false
config :hava, Uploader, enabled: false

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
