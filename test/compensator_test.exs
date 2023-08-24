defmodule CompensatorTest do
  use ExUnit.Case, async: false
  # import Mox
  # setup :set_mox_from_context
  # setup :verify_on_exit!

  @tag :time_consuming
  test "test proper dispatch in compensator" do
    # environment setup
    put_env(:max_call_gap, 1_000)
    put_env(:max_call_duration, 1_000)
    put_env(:min_send_ratio, 1)
    duration = 5_000
    server_count = 5

    # starting and initiating servers
    Application.put_env(:hava, :uploader, Hava.UploaderMockServer)
    start_supervised!({Hava.UploaderMockServer, server_count: server_count})
    start_supervised!(Hava.Compensator)

    # calling compensate on a one round all servers call fit
    servers = Hava.UploaderMockServer.get_servers_internal()

    receive = calc_all_server_call_send_amount(servers, 1_000)
    Hava.Compensator.compensate(receive, duration)

    # sleep more that duration 
    IO.puts("waiting for more than #{duration} ")
    :timer.sleep(duration + 1_000)
    called_servers = Hava.UploaderMockServer.get_called_servers()
    assert called_servers |> Enum.count() == server_count
    called_server1 = called_servers |> Enum.at(0)
    called_server2 = called_servers |> Enum.at(1)
    assert DateTime.diff(called_server2.call_time, called_server1.call_time, :second) == 1
    called_server3 = called_servers |> Enum.at(2)
    assert DateTime.diff(called_server3.call_time, called_server2.call_time, :second) == 1
    called_server4 = called_servers |> Enum.at(3)
    assert DateTime.diff(called_server4.call_time, called_server3.call_time, :second) == 1
    # and so on ..

    #
    # on each run there should be new random speeds
    #
    servers = Hava.UploaderMockServer.get_servers_internal()
    new_receive = calc_all_server_call_send_amount(servers, 1_000)
    assert new_receive != receive

    #
    # for double duration receive amount there should be double server calls
    #
    receive = calc_all_server_call_send_amount(servers, 2_000)
    Hava.UploaderMockServer.clear_called_servers()
    Hava.Compensator.compensate(receive, duration)
    IO.puts("waiting for more than #{duration} ")
    :timer.sleep(duration + 1_000)

    assert Hava.UploaderMockServer.get_called_servers()
           |> Enum.reduce(0, fn server, acc -> server.call_count + acc end) == server_count * 2

    #
    # for non positive receve values there should not be any sever call
    #
    Hava.UploaderMockServer.clear_called_servers()
    Hava.Compensator.compensate(0, duration)
    IO.puts("waiting for more than #{duration} ")
    :timer.sleep(duration + 1_000)
    assert Hava.UploaderMockServer.get_called_servers() |> Enum.count() == 0
  end

  defp calc_all_server_call_send_amount(servers, duration_per_server) do
    servers
    |> Enum.reduce(0, fn server, acc ->
      acc + server.speed * duration_per_server / 1_000 * 1024 * 1024 / 8
    end)
    |> round()
  end

  defp put_env(key, value) do
    Application.put_env(
      :hava,
      :run_pick,
      Application.get_env(:hava, :run_pick) |> Keyword.put(key, value)
    )
  end
end
