defmodule RunPickTest do
  alias Hava.Aux.RunPickItem
  alias Hava.Aux.RunPick
  use ExUnit.Case, async: true

  test "pick next test" do
    servers = [
      %{server_id: "1", speed: 2.4},
      %{server_id: "2", speed: 0},
      %{server_id: "3", speed: 50.1}
    ]

    default_duration = get_env(:max_call_duration)

    run_pick =
      servers
      |> RunPick.new(500, 10_000)
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
    put_env(:max_call_gap, 1_000)

    run_pick =
      servers
      |> RunPick.new(500, 10_000)
      |> RunPick.pick_on_max_call_gap()

    assert run_pick.items |> length() == 10

    # on zero call, there will be no selection 
    put_env(:max_call_gap, 0)

    run_pick =
      servers
      |> RunPick.new(500, 10_000)
      |> RunPick.pick_on_max_call_gap()

    assert run_pick.items |> length() == 0
  end

  test "run pick based on send required" do
    servers =
      1..10
      |> Enum.map(&%{server_id: to_string(&1), speed: 10})

    run_pick =
      servers
      |> RunPick.new(500, 10_000)
      |> RunPick.pick_on_send_required()

    # required send in mega bit / (per server mega bit send)
    assert run_pick.items |> length() ==
             (run_pick.send_required * 8 /
                (10 * get_env(:max_call_duration) / 1_000))
             |> trunc()
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
