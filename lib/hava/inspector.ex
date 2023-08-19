defmodule Hava.Inspector do
  require Logger
  alias Hava.Compensator
  alias Hava.Stats
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_state) do
    interface = Application.get_env(:hava, Inspector)[:usage_interface]
    interval = Application.get_env(:hava, Inspector)[:interval]
    usage = Stats.read(interface)
    Process.send_after(self(), :inspect, interval)
    {:ok, %{interface: interface, interval: interval, usage: usage}}
  end

  def handle_info(:inspect, %{
        interface: interface,
        interval: interval,
        usage: %{send: _send, receive: receive}
      }) do
    # reading new usage stats
    new_usage = %{send: _new_send, receive: new_receive} = Stats.read(interface)

    # calculating new extra receive difference and compensate
    # Logger.debug("pre receive: #{receive |> byte_to_mega_byte()}, send: #{send |> byte_to_mega_byte()}")
    # Logger.debug("new receive: #{new_receive |> byte_to_mega_byte()}, send: #{new_send |> byte_to_mega_byte()}")
    (new_receive - receive)
    |> Compensator.compensate(interval)

    Process.send_after(self(), :inspect, interval)
    {:noreply, %{interface: interface, interval: interval, usage: new_usage}}
  end

  # defp byte_to_mega_byte(bytes), do: bytes/1024/1024 |> Float.round(2)
end
