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
        %{servers: servers, server_index: server_index}
      ) do
    run_pick = RunPick.pick_uniform(servers, receive, duration, server_index)
    for item <- run_pick.items do
      Process.send_after(self(), {:run, item}, item.after)
    end

    {:noreply,
     %{
       servers: servers,
       server_index: run_pick.index
     }}
  end

  def handle_cast({:update_speed, server_index, speed}, state = %{servers: servers}) do
    {:noreply,
     %{
       state
       | servers:
           List.replace_at(servers, server_index, %{
             Enum.at(servers, server_index)
             | speed: speed
           })
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
    Logger.info(
      "----------- compensate request; receive: #{receive / 1024 / 1024 |> Float.round(2)} MB, within: #{duration} ----------"
    )

    GenServer.cast(__MODULE__, {:compensate, receive, duration})
  end
end
