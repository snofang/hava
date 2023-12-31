defmodule Hava.UploaderMockServer do
  require Logger
  use GenServer
  @behaviour Hava.Uploader

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(args) do
    servers =
      1..args[:server_count]
      |> Enum.map(fn i ->
        %{
          server_id: to_string(i),
          # TODO: to bring speed initialization logic into Uploader
          speed: Application.get_env(:hava, Compensator)[:initial_speed],
          call_count: 0,
          call_time: nil
        }
      end)

    {:ok, %{servers: servers}}
  end

  def handle_call(:get_servers, _from, state = %{servers: servers}) do
    {:reply, servers, state}
  end

  def handle_call({:upload, server_id}, _from, state = %{servers: servers}) do
    speed = (:rand.uniform() * (140 - 8) + 8) |> Float.round(2)

    servers =
      servers
      |> Enum.map(fn s ->
        if s.server_id == server_id do
          %{
            server_id: s.server_id,
            speed: speed,
            call_count: s.call_count + 1,
            call_time: DateTime.now("Etc/UTC") |> elem(1)
          }
        else
          s
        end
      end)

    {:reply, %{server_id: server_id, speed: speed}, %{state | servers: servers}}
  end

  def handle_call(:called, _from, state = %{servers: servers}) do
    {:reply,
     servers
     |> Enum.filter(fn s -> s.call_count > 0 end), state}
  end

  def handle_cast(:clear, state = %{servers: servers}) do
    {:noreply,
     %{
       state
       | servers:
           servers
           |> Enum.map(fn s -> %{s | call_count: 0, call_time: nil} end)
     }}
  end

  def get_servers() do
    GenServer.call(__MODULE__, :get_servers)
    |> Enum.map(fn server -> server.server_id end)
  end

  def get_servers_internal() do
    GenServer.call(__MODULE__, :get_servers)
  end

  def upload(server_id, _duration) do
    %{server_id: _, speed: speed} = GenServer.call(__MODULE__, {:upload, server_id})
    speed
  end

  @spec get_called_servers() ::
          list(%{
            server_id: binary,
            speed: float,
            call_cout: non_neg_integer,
            call_time: DateTime.t()
          })
  def get_called_servers() do
    GenServer.call(__MODULE__, :called)
  end

  def clear_called_servers() do
    GenServer.cast(__MODULE__, :clear)
  end
end
