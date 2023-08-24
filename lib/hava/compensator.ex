defmodule Hava.Compensator do
  @moduledoc """
  This GenServer aquires list of servers for upload and 
  responds on demands for compensating the download increase.
  It selects upload servers on a round robin fashin vi `RunPick` module
  and due to small number of servers this currently implemented 
  by index based accces on list of servers.
  TODO: to optimize the index based round robin selection mechanism
  """
  require Logger
  alias Hava.Aux.RunPickItem
  alias Hava.Aux.RunPick
  alias Hava.Uploader
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_init_args) do
    initial_speed = Application.get_env(:hava, Compensator)[:initial_speed]

    servers =
      Uploader.get_servers()
      |> Enum.map(&%{server_id: &1, speed: initial_speed})

    {:ok, %{servers: servers, server_index: 0}}
  end

  def handle_cast(
        {:compensate, receive, duration},
        state = %{servers: servers, server_index: server_index}
      ) do
    Logger.info("""
    ------- compensate request -------- 
    Receive: #{(receive / 1024 / 1024) |> Float.round(2)} MB 
    Duration: #{(duration / 1_000) |> trunc} 
    Total servers: #{servers |> Enum.count()}
    Active servers: #{servers |> Enum.filter(fn s -> s.speed > 0 end) |> Enum.count()}
    -----------------------------------
    """)

    if(receive > 0) do
      run_pick = RunPick.pick_uniform(servers, receive, duration, server_index)

      for item <- run_pick.items do
        Process.send_after(self(), {:run, item}, item.after)
      end

      {:noreply,
       %{
         servers: servers,
         server_index: run_pick.index
       }}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:update_speed, server_index, speed}, state = %{servers: servers}) do
    {:noreply,
     %{
       state
       | servers:
           List.update_at(servers, server_index, &%{&1 | speed: speed})
           |> recap_zero_speed_servers(Application.get_env(:hava, Compensator)[:recap_ratio])
     }}
  end

  def handle_info({:run, %RunPickItem{} = item}, state) do
    Task.Supervisor.start_child(Hava.TaskSupervisor, fn ->
      speed = Uploader.upload(item.server_id, item.duration)
      GenServer.cast(__MODULE__, {:update_speed, item.server_index, speed})
    end)

    {:noreply, state}
  end

  @doc """
  tries to compensate extra given `receive`(mega bit) within given `duration`(milliseconds) 
  unit measures are in Mega bit 
  """
  def compensate(receive, duration) do
    GenServer.cast(__MODULE__, {:compensate, receive, duration})
  end

  @doc """
  assigns speed of 1 to those `servers` memeber with zero speed if
  count of them exceed `thershold_ratio`.
  """
  def recap_zero_speed_servers(servers, thershold_ratio)
      when thershold_ratio >= 0 do
    zero_servers = servers |> Enum.filter(fn s -> s.speed <= 0 end)
    zero_ratio = ((zero_servers |> Enum.count()) / (servers |> Enum.count())) |> Float.round(2)

    if zero_ratio > thershold_ratio do
      Logger.info("""
      recapturing servers by ratio: #{thershold_ratio}, 
      servers: #{inspect(zero_servers |> Enum.map(& &1.server_id))}
      """)

      servers |> Enum.map(fn s -> if(s.speed == 0, do: %{s | speed: 1}, else: s) end)
    else
      servers
    end
  end

  def recap_zero_speed_servers([], _thershold_ratio) do
    []
  end
end
