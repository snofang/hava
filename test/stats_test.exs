defmodule StatsTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!

  Application.put_env(:hava, :cmd_wrapper, Hava.CmdWrapperMock)
  Application.put_env(:hava, :stats, Hava.StatsDev)

  test "success reading /proc/net/dev and extracting send & receive" do
    Hava.CmdWrapperMock
    |> expect(:run, fn "cat /proc/net/dev", _ ->
      {:ok,
       """
       Inter-|   Receive                                                |  Transmit face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
       lo: 452802901  346055    0    0    0     0          0         0 452802901  346055    0    0    0     0       0          0
       enp2s0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
       wlp3s0: 12078357072 13007468    0 3396    0     0          0         0 2678896827 7843069    0    0    0     0       0          0
       docker0:  104953    1385    0    0    0     0          0         0  4767074   26742    0    0    0     0       0          0
       veth1ef0ffe:  124343    1385    0    0    0     0          0         0  4767074   26742    0    0    0     0       0          0
       tun0:  773958    1508    0    0    0     0          0         0   193181    1436    0    0    0     0       0          0
       """}
    end)

    assert Hava.Stats.read("wlp3s0") == %{
             send: 2_678_896_827,
             receive: 12_078_357_072
           }
  end
end
