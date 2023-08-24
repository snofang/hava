import Config

if config_env() == :prod do
  to_bool = fn s -> if(s == "true", do: true, else: false) end
  config :hava, Inspector, enabled: to_bool.(System.get_env("HAVA_ENABLED") || true)
  config :hava, Compensator, enabled: to_bool.(System.get_env("HAVA_ENABLED") || true)
  config :hava, Uploader, enabled: to_bool.(System.get_env("HAVA_ENABLED") || true)

  config :hava, Inspector,
    usage_interface:
      System.get_env("HAVA_INTERFACE") ||
        raise("""
        missing HAVA_INTERFACE definition
        it should be specified which network interface 
        is going to be considered as a source of traffic inspection
        e.g. eth0, ens3, ...
        """)

  config :hava, Inspector,
    interval: (System.get_env("HAVA_INTERVAL") |> Integer.parse() |> elem(0)) * 1_000 || 20_000

  config :hava, :run_pick,
    max_call_gap:
      (System.get_env("HAVA_MAX_CALL_GAP") |> Integer.parse() |> elem(0)) * 1_000 || 10_000

  config :hava, :run_pick,
    max_call_duration:
      (System.get_env("HAVA_MAX_CALL_DURATION") |> Integer.parse() |> elem(0)) * 1_000 || 10_000

  config :hava, :run_pick,
    min_send_ratio: System.get_env("HAVA_SEND_RATIO") |> Integer.parse() |> elem(0) || 10

  config :hava, Compensator,
    recap_ratio: System.get_env("HAVA_RECAP_RATIO") |> Float.parse() |> elem(0) || 0.75
end
