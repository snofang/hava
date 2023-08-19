import Config

if config_env() == :prod do
  config :hava, Inspector,
    usage_interface:
      System.get_env("HAVA_NET_INTERFACE") || "ens3"
        # raise("""
        # missing HAVA_NET_INTERFACE definition
        # it should be specified which network interface 
        # is going to be considered as a source of traffic inspection
        # e.g. eth0, ...
        # """)
end
