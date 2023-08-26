defmodule UploaderIperfTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!
  @moduletag :skip

  Application.put_env(:hava, :uploader, Hava.UploaderIperf)

  test "get server list successfully" do
    Hava.HttpClientMock
    |> expect(:get, fn "https://iperf3serverlist.net/serverlist.json" ->
      {:ok, iperf_list_normal()}
    end)

    assert Hava.Uploader.get_servers() == server_list_normal()
  end

  test "get server list failure" do
    Hava.HttpClientMock
    |> expect(:get, fn _ ->
      {:error, iperf_list_error()}
    end)

    assert Hava.Uploader.get_servers() == []
  end

  test "upload successfully" do
    Hava.CmdWrapperMock
    |> expect(
      :run,
      fn "iperf3 -c speedtestfl.telecom.mu -p 5201-5209 --zerocopy --time 5 --version4", _ ->
        {:ok,
         """
         Connecting to host speedtestfl.telecom.mu, port 5201
         [  5] local xxx.xxx.xxx.xxx port 51892 connected to 197.227.12.18 port 5201
         [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
         [  5]   0.00-1.00   sec   225 KBytes  1.84 Mbits/sec    0   31.1 KBytes       
         [  5]   1.00-2.00   sec   346 KBytes  2.84 Mbits/sec    1   62.2 KBytes       
         [  5]   2.00-3.00   sec  1.37 MBytes  11.5 Mbits/sec    3    221 KBytes       
         [  5]   3.00-4.00   sec  2.05 MBytes  17.2 Mbits/sec    2    551 KBytes       
         [  5]   4.00-5.00   sec  1.25 MBytes  10.5 Mbits/sec    6   1.45 MBytes       
         - - - - - - - - - - - - - - - - - - - - - - - - -
         [ ID] Interval           Transfer     Bitrate         Retr
         [  5]   0.00-5.00   sec  5.23 MBytes  8.77 Mbits/sec   12             sender
         [  5]   0.00-5.00   sec  3.02 MBytes  5.06 Mbits/sec                  receiver
         """}
      end
    )

    assert Hava.Uploader.upload("speedtestfl.telecom.mu -p 5201-5209", 5_000) == 8.77
  end

  test "upload failure" do
    Hava.CmdWrapperMock
    |> expect(
      :run,
      fn "iperf3 -c speedtestfl.telecom.mu -p 5201-5209 --zerocopy --time 5 --version4", _ ->
        {:ok,
         """
         iperf3: error - the server is busy running a test. try again later
         """}
      end
    )

    assert Hava.Uploader.upload("speedtestfl.telecom.mu -p 5201-5209", 5_000) == 0
  end

  def iperf_list_error() do
    %{
      status_code: 404,
      body: """
      somthing ...
      """
    }
  end

  def iperf_list_normal() do
    %{
      status_code: 200,
      body: """
      {
        "count": 137,
        "next": null,
        "previous": null,
        "results": [
          {
            "id": 3,
            "order": "3.00000000000000000000",
            "IP": "iperf3 -c speedtestfl.telecom.mu -p 5201-5209",
            "OPTIONS": [
              {
                "id": 1769,
                "value": "-R",
                "color": "dark-blue"
              }
            ],
            "GB/S": null,
            "COUNTRY": "MU",
            "SITE": "Floreal",
            "CONTINENT": "Africa",
            "PROVIDER": "Mauritius Telecom",
            "STATUS": ""
          },
          {
            "id": 4,
            "order": "4.00000000000000000000",
            "IP": "iperf3 -c speedtest.telecom.mu -p 5201-5209",
            "OPTIONS": [
              {
                "id": 1769,
                "value": "-R",
                "color": "dark-blue"
              }
            ],
            "GB/S": null,
            "COUNTRY": "MU",
            "SITE": "Port Louis",
            "CONTINENT": "Africa",
            "PROVIDER": "Mauritius Telecom",
            "STATUS": ""
          },
          {
            "id": 5,
            "order": "5.00000000000000000000",
            "IP": "iperf3 -c speedtestrh.telecom.mu -p 5201-5209",
            "OPTIONS": [
              {
                "id": 1769,
                "value": "-R",
                "color": "dark-blue"
              }
            ],
            "GB/S": null,
            "COUNTRY": "MU",
            "SITE": "Rose Hill",
            "CONTINENT": "Africa",
            "PROVIDER": "Mauritius Telecom",
            "STATUS": ""
          },
          {
            "id": 8,
            "order": "8.00000000000000000000",
            "IP": "iperf3 -c 154.73.174.30",
            "OPTIONS": [],
            "GB/S": null,
            "COUNTRY": "SN",
            "SITE": "Dakar",
            "CONTINENT": "Africa",
            "PROVIDER": "ARC",
            "STATUS": ""
          }
        ]
      }
      """
    }
  end

  def server_list_normal() do
    [
      "iperf3 -c speedtestfl.telecom.mu -p 5201-5209",
      "iperf3 -c speedtest.telecom.mu -p 5201-5209",
      "iperf3 -c speedtestrh.telecom.mu -p 5201-5209",
      "iperf3 -c 154.73.174.30"
    ]
  end
end
