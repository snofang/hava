import Config

config :hava, Inspector,
  # in milliseconds
  interval: 10_000,
  # net usage stats handler module
  usage_stats: Hava.UsageStats,
  # net intefrace as the source of usage data
  usage_interface: "wlp3s0",
  # net usage receive compensator
  usage_compensator: Hava.Compensator

config :hava, Compensator,
  # compensation ratio
  ratio: 12,
  # initial server's speed in mega byte per second
  initial_speed: 10,
  # the amount of each call to each server takes 
  # this is directly related to inspector's interval and shouldn't
  # be greater than it.
  session_duratin: 5_000

config :hava, :cmd_wrapper, Hava.CmdWrapperImpl
config :hava, :uploader, Hava.UploaderLibreSt

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
