import Config

config :hava, Inspector,
  # in milliseconds
  interval: 30_000,
  # net usage stats handler module
  usage_stats: Hava.UsageStats,
  # net intefrace as the source of usage data
  usage_interface: "wlp3s0",
  # net usage receive compensator
  usage_compensator: Hava.Compensator


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
