import Config

config :hava, Inspector,
  # in milliseconds
  interval: 100,
  enabled: false

config :hava, Uploader,
  # enable/disable real upload
  enabled: true

# Print only warnings and errors during test
config :logger, level: :warning

