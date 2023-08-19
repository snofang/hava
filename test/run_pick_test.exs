defmodule RunPickTest do
  alias Hava.Aux.RunPickItem
  alias Hava.Aux.RunPick
  use ExUnit.Case, async: false

  test "pick next test" do
    servers = [
      %{server_id: "1", speed: 2.4},
      %{server_id: "2", speed: 0},
      %{server_id: "3", speed: 50.1}
    ]

    default_duration = get_env(:max_call_duration)

    run_pick =
      servers
      |> RunPick.new(500 * 1024 * 1024, 10_000)
      |> RunPick.pick_next()

    assert run_pick.index == 1

    assert %RunPickItem{server_id: "1", speed: 2.4, duration: ^default_duration} =
             run_pick.items |> Enum.at(0)

    run_pick = run_pick |> RunPick.pick_next()
    assert run_pick.index == 0
    assert %RunPickItem{server_id: "3", speed: 50.1} = run_pick.items |> Enum.at(1)

    run_pick = run_pick |> RunPick.pick_next()
    assert run_pick.index == 1
    assert %RunPickItem{server_id: "1", speed: 2.4} = run_pick.items |> Enum.at(0)

    assert run_pick.items |> length() == 3
  end

  test "run pick initialization test" do
    run_pick = RunPick.new([], 1, 1)

    assert get_env(:max_call_gap) == run_pick.gap
    assert get_env(:min_send_ratio) * run_pick.receive == run_pick.send_required
  end

  test "run pick based on max gap value test " do
    servers =
      1..10
      |> Enum.map(&%{server_id: to_string(&1), speed: 10})

    # normal call gap limit
    run_pick =
      servers
      |> RunPick.new(500 * 1024 * 1024, 10_000)

    run_pick = %{run_pick | gap: 1_000}
    run_pick = run_pick |> RunPick.pick_on_max_call_gap()
    assert run_pick.items |> length() == 10
    # asserting index proper assignment 
    assert Enum.to_list(0..9) == run_pick.items |> Enum.map(fn item -> item.server_index end)

    # asserting id proper assignment 
    assert Enum.to_list(1..10) ==
             run_pick.items
             |> Enum.map(fn item -> item.server_id |> Integer.parse() end)
             |> Enum.map(fn {id, _} -> id end)

    # on zero call, there will be no selection 
    run_pick =
      servers
      |> RunPick.new(500 * 1024 * 1024, 10_000)

    run_pick = %{run_pick | gap: 0}
    run_pick = run_pick |> RunPick.pick_on_max_call_gap()
    assert run_pick.items |> length() == 0
  end

  test "run pick based on send required" do
    servers =
      1..10
      |> Enum.map(&%{server_id: to_string(&1), speed: 10})

    run_pick =
      servers
      |> RunPick.new(500 * 1024 * 1024, 10_000)
      |> RunPick.pick_on_send_required()

    # required send in bytes / (per server bytes send)
    assert run_pick.items |> length() ==
             (run_pick.send_required /
                (10 * get_env(:max_call_duration) / 1_000 * 1024 * 1024 / 8))
             |> trunc()
  end

  test "adjust duration test - adjusted input" do
    put_env(:max_call_gap, 5_000)
    put_env(:max_call_duration, 5_000)
    put_env(:min_send_ratio, 12)
    # the followings yields 6.5 mega byte per seconds
    # (10+15+13+14)/8 = 6.5
    servers = [
      %{server_id: "1", speed: 10},
      %{server_id: "2", speed: 15},
      %{server_id: "3", speed: 13},
      %{server_id: "4", speed: 14}
    ]

    receive =
      ((10 + 15 + 13 + 14) / 8 * get_env(:max_call_duration) * 1024 * 1024 / 1_000 /
         get_env(:min_send_ratio))
      |> round()

    duration = 20_000

    run_pick =
      servers
      |> RunPick.new(receive, duration)
      |> RunPick.pick_on_max_call_gap()

    assert run_pick.items |> length() == (duration / get_env(:max_call_gap)) |> round()
    first_item = run_pick.items |> List.first()
    assert first_item.duration == get_env(:max_call_duration)

    # calling pick_on_send_required should have no effect on items
    run_pick = run_pick |> RunPick.pick_on_send_required()
    assert run_pick.items |> length() == 4

    # calliing adjust time should have no efect also
    run_pick = run_pick |> RunPick.adjust_pick_durations()
    first_item = run_pick.items |> List.first()
    assert first_item.duration == get_env(:max_call_duration)
  end

  test "run pick normalized test" do
    put_env(:max_call_gap, 5_000)
    put_env(:max_call_duration, 5_000)
    put_env(:min_send_ratio, 12)

    # (10+15+13+14)/8 = 6.5
    servers = [
      %{server_id: "1", speed: 10},
      %{server_id: "2", speed: 15},
      %{server_id: "3", speed: 13},
      %{server_id: "4", speed: 14}
    ]

    receive =
      ((10 + 15 + 13 + 14) / 8 * (get_env(:max_call_duration) - 1_000) * 1024 * 1024 / 1_000 /
         get_env(:min_send_ratio))
      |> round()

    run_pick = RunPick.pick_uniform(servers, receive, 20_000)
    assert run_pick.items |> length() == 4
    first_item = run_pick.items |> List.first()
    assert first_item.duration == get_env(:max_call_duration) - 1_000

    assert [0, 5_000, 10_000, 15_000] = run_pick.items |> Enum.map(fn item -> item.after end)
  end

  test "run pick adjust after test " do
    put_env(:max_call_gap, 3_000)

    run_pick =
      1..5
      |> Enum.map(fn i -> %{server_id: to_string(i), speed: nil} end)
      |> RunPick.new(1, 15_000)
      |> RunPick.pick_on_max_call_gap()
      |> RunPick.adjust_pick_after()

    assert [0, 3_000, 6_000, 9_000, 12_000] =
             run_pick.items |> Enum.map(fn item -> item.after end)
  end

  test "run pick normalized with all speed zero test" do
    put_env(:max_call_gap, 5_000)
    put_env(:max_call_duration, 5_000)
    put_env(:min_send_ratio, 12)

    servers = [
      %{server_id: "1", speed: 0},
      %{server_id: "2", speed: 0},
      %{server_id: "3", speed: 0},
      %{server_id: "4", speed: 0}
    ]

    run_pick = RunPick.pick_uniform(servers, 100*1024*1024, 20_000)
    assert run_pick.items |> length() == 0
  end
  
  defp put_env(key, value) do
    Application.put_env(
      :hava,
      :run_pick,
      Application.get_env(:hava, :run_pick) |> Keyword.put(key, value)
    )
  end

  defp get_env(key) do
    Application.get_env(:hava, :run_pick)[key]
  end
end
