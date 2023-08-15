defmodule UploaderTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!


  Mox.defmock(Hava.CmdWrapperMock, for: Hava.CmdWrapper)
  Application.put_env(:hava, :cmd_wrapper, Hava.CmdWrapperMock)

  test "get server list successfully" do
    Hava.CmdWrapperMock
    |> expect(:run, fn "librespeed-cli --list", _ -> {:ok, librespeed_list_normal()} end)

    assert Hava.Uploader.get_servers() == server_list_normal()
  end

  test "get server list failure" do
    Hava.CmdWrapperMock
    |> expect(:run, fn "librespeed-cli --list", _ -> {:ok, librespeed_list_failure()} end)

    assert Hava.Uploader.get_servers() == []
  end

  test "upload successfully" do
    Hava.CmdWrapperMock
    |> expect(
      :run,
      fn "librespeed-cli --no-download --simple --no-icmp --duration 1 --server 51", _ ->
        {:ok,
         """
         Ping:   167.55 ms       Jitter: 137.64 ms
         Download rate:  0.00 Mbps
         Upload rate:    7.85 Mbps
         """}
      end
    )

    assert Hava.Uploader.upload("51", 1) == 7.85
  end

  test "upload failure" do
    Hava.CmdWrapperMock
    |> expect(
      :run,
      fn "librespeed-cli --no-download --simple --no-icmp --duration 1 --server 51", _ ->
        {:ok, ""}
      end
    )

    assert Hava.Uploader.upload("51", 1) == 0
  end

  def librespeed_list_normal() do
    """
    Retrieving server list from https://librespeed.org/backend-servers/servers.php
    51: Amsterdam, Netherlands (Clouvider) (http://ams.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clouvider.c o.uk/]
    53: Atlanta, United States (Clouvider) (http://atl.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clouvider.c o.uk/]
    75: Bangalore, India (DigitalOcean) (http://in1.backend.librespeed.org/)  [Sponsor: DigitalOcean @ https://www.digitalocean.com]
    33: Bari, Italy (GARR) (https://st-be-ba1.infra.garr.it)  [Sponsor: Consortium GARR @ https://garr.it]
    34: Bologna, Italy (GARR) (https://st-be-bo1.infra.garr.it)  [Sponsor: Consortium GARR @ https://garr.it]
    50: Frankfurt, Germany (Clouvider) (http://fra.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clouvider.co.uk /]
    86: Frankfurt, Germany (FRA01) (https://speedtest.lumischvps.cloud/)  [Sponsor: LumischVPS @ https://discord.gg/GxYzPwJmA2]
    77: Ghom, Iran (Amin IDC) (https://fastme.ir/)  [Sponsor: Bardia Moshiri @ https://bardia.tech/]
    22: Helsinki, Finland (3) (Hetzner) (http://finew.openspeed.org/)  [Sponsor: Daily Health Insurance Group @ https://dhig.net/]
    24: Helsinki, Finland (5) (Hetzner) (http://fast.kabi.tk/)  [Sponsor: KABI.tk @ https://kabi.tk]
    70: Johannesburg, South Africa (Host Africa) (http://za1.backend.librespeed.org/)  [Sponsor: HOSTAFRICA @ https://www.hostafrica.c o.za]
    49: London, England (Clouvider) (http://lon.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clouvider.co.uk/]
    54: Los Angeles, United States (1) (Clouvider) (http://la.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clou vider.co.uk/]
    52: New York, United States (2) (Clouvider) (http://nyc.speedtest.clouvider.net/backend)  [Sponsor: Clouvider @ https://www.clouvi der.co.uk/]
    43: Nottingham, England (LayerIP) (https://uk1.backend.librespeed.org)  [Sponsor: fosshost.org @ https://fosshost.org]
    28: Nuremberg, Germany (1) (Hetzner) (http://de1.backend.librespeed.org)  [Sponsor: Snopyta @ https://snopyta.org]
    27: Nuremberg, Germany (2) (Hetzner) (http://de4.backend.librespeed.org)  [Sponsor: LibreSpeed @ https://librespeed.org]
    30: Nuremberg, Germany (3) (Hetzner) (http://de3.backend.librespeed.org)  [Sponsor: LibreSpeed @ https://librespeed.org]
    31: Nuremberg, Germany (4) (Hetzner) (http://de5.backend.librespeed.org)  [Sponsor: LibreSpeed @ https://librespeed.org]
    46: Nuremberg, Germany (6) (Hetzner) (http://librespeed.lukas-heinrich.com/)  [Sponsor: luki9100 @ https://lukas-heinrich.com/]
    74: Poznan, Poland (INEA) (https://speedtest.kamilszczepanski.com)  [Sponsor: Kamil Szczepański @ https://kamilszczepanski.com]
    79: Prague, Czech Republic (CESNET) (http://speedtest.cesnet.cz)  [Sponsor: CESNET @ https://www.cesnet.cz]
    85: Prague, Czech Republic (Turris) (http://librespeed.turris.cz)  [Sponsor: Turris @ https://www.turris.com]
    35: Roma, Italy (GARR) (https://st-be-rm2.infra.garr.it)  [Sponsor: Consortium GARR @ https://garr.it]
    68: Singapore (Salvatore Cahyo) (https://speedtest.dsgroupmedia.com)  [Sponsor: Salvatore Cahyo @ https://salvatorecahyo.my.id]
    76: Tehran, Iran (Fanava) (https://speedme.ir/)  [Sponsor: Bardia Moshiri @ https://bardia.tech]
    80: Tehran, Iran (Faraso) (https://st.bardia.tech)  [Sponsor: Bardia Moshiri @ https://bardia.tech/]
    82: Tokyo, Japan (A573) (https://librespeed.a573.net/)  [Sponsor: A573 @ https://mirror.a573.net/]
    69: Vilnius, Lithuania (RackRay) (http://lt1.backend.librespeed.org/)  [Sponsor: Time4VPS @ https://www.time4vps.com]
    78: Virginia, United States, OVH (https://speed.riverside.rocks/)  [Sponsor: Riverside Rocks @ https://riverside.rocks]
    """
  end

  def librespeed_list_failure() do
    """
    Retrieving server list from https://librespeed.org/backend-servers/servers.php
    Retry with /.well-known/librespeed
    Error when fetching server list: Get "https://librespeed.org/backend-servers/servers.php/.well-known/librespeed": dial tcp: lookup
    librespeed.org on 127.0.0.53:53: server misbehaving
    Terminated due to error
    """
  end

  def server_list_normal() do
    [
      "51",
      "53",
      "75",
      "33",
      "34",
      "50",
      "86",
      "77",
      "22",
      "24",
      "70",
      "49",
      "54",
      "52",
      "43",
      "28",
      "27",
      "30",
      "31",
      "46",
      "74",
      "79",
      "85",
      "35",
      "68",
      "76",
      "80",
      "82",
      "69",
      "78"
    ]
  end
end
