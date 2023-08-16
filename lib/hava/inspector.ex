defmodule Hava.Inspector do
  alias Hava.Stats
  use GenServer

  @interval Application.compile_env(:hava, [Inspector, :interval])
  @usage_compensator Application.compile_env(:hava, [Inspector, :usage_compensator])

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_state) do
    interface = Application.get_env(:hava, Inspector)[:usage_interface]
    usage = Stats.read(interface)
    Process.send_after(self(), :inspect, @interval)
    {:ok, %{interface: interface, usage: usage}}
  end

  def handle_info(:inspect, %{interface: interface, usage: %{send: send, receive: receive}}) do
    # reading new usage stats
    new_usage = %{send: new_send, receive: new_receive} = Stats.read(interface)

    # calculating new extra receive difference and compensate
    (new_receive - new_send - (receive - send))
    |> @usage_compensator.compensate(@interval)

    Process.send_after(self(), :inspect, @interval)
    {:noreply, %{interface: interface, usage: new_usage}}
  end
end
