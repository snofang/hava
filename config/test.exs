import Config

config :hava, Inspector, enabled: false
config :hava, Compensator, enabled: false
# all the uploads in tests are mocked; in command level.
# this is needed to reach the command level
config :hava, Uploader, enabled: true

# Print only warnings and errors during test
config :logger, level: :warning
