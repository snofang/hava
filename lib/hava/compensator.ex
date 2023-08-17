defmodule Hava.Compensator do
  @moduledoc """
  This GenServer aquires list of servers for upload and 
  responds on demands for compensating the download increase.
  It should select the upload servers on a round robin fashin
  and due to small number of servers this currently implemented 
  by index based accces on list of servers.
  TODO: to optimize the index based round robin selection mechanism
  """
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
    IO.puts("--- handle_cast :compensate ---- receive: #{receive}\n ----- \n #{inspect servers}")
    ratio = Application.get_env(:hava, Compensator)[:ratio]
    session_duration = fetch_session_duration()

    server_ids =
      pick_servers(
        %{servers: servers, server_index: server_index},
        receive * ratio,
        session_duration
      )

    duration_step = (duration - session_duration / length(server_ids)) |> trunc()
    dispatch_tasks(server_ids, 0, duration_step)

    {:noreply,
     %{
       servers: servers,
       server_index: Integer.mod(server_index + length(server_ids), length(servers))
     }}
  end

  def handle_info({:run, server_index, duration}, state = %{servers: servers}) do
    Task.Supervisor.start_child(Hava.TaskSupervisor, fn ->
      speed = Uploader.upload(Enum.at(servers, server_index), duration)
      send(self(), {:update_speed, server_index, speed})
    end)

    {:noreply, state}
  end

  def handle_info(
        {:update_speed, server_index, speed},
        state = %{servers: servers}
      ) do
    {
      :noreply,
      %{
        state
        | servers:
            List.replace_at(servers, server_index, %{
              Enum.at(servers, server_index)
              | speed: speed
            })
      }
    }
  end

  @doc """
  tries to compensate extra given `receive`(mega bit) within given `duration`(milliseconds) 
  unit measures are in Mega bit 
  """
  def compensate(receive, duration) do
    GenServer.cast(__MODULE__, {:compensate, receive, duration})
  end

  @spec pick_servers(
          %{servers: [binary], server_index: non_neg_integer},
          non_neg_integer,
          non_neg_integer,
          [binary]
        ) :: [binary]
  defp pick_servers(
         %{servers: servers, server_index: server_index},
         receive,
         duration,
         selected_server_ids \\ []
       ) do
    if duration <= 0 do
      selected_server_ids
    else
      current_server = Enum.at(servers, server_index)

      IO.puts("receive: #{receive}, server: #{inspect(current_server)}, duration: #{duration}")
      pick_servers(
        %{
          servers: servers,
          server_index: Integer.mod(server_index + 1, length(servers))
        },
        receive - (current_server.speed * duration),
        duration,
        [current_server.server_id | selected_server_ids]
      )
    end
  end

  @spec dispatch_tasks([binary], non_neg_integer, non_neg_integer) :: any
  defp dispatch_tasks(server_ids, time, duration_step)

  defp dispatch_tasks([head | tail], time, duration_step) do
    Process.send_after(self(), {:run, head}, time)
    dispatch_tasks(tail, time + duration_step, duration_step)
  end

  defp dispatch_tasks([], _time, _duration_step) do
  end

  defp fetch_session_duration() do
    Application.get_env(:hava, Compensator)[:session_duration]
  end

  def handle_call({:get_servers}, _from, state) do
    {:reply, state.servers, state}
  end
end
