import Config

# Do not print debug messages in production
config :logger, level: :info


# TODO: remove this 
config :hava, Inspector,
  # in milliseconds
  interval: 20_000,
  # net intefrace as the source of usage data
  usage_interface: "wlp3s0",
  enabled: true

