defmodule Hava.UploaderIperf do
  require Logger
  alias Hava.CmdWrapper
  @behaviour Hava.Uploader
  @call_timeout 20_000

  @doc """
  Fetchs available server ids 
  """
  @spec get_servers() :: [binary]
  def get_servers() do
    result =
      case Application.get_env(:hava, :http_client).get(
             "https://iperf3serverlist.net/serverlist.json"
           ) do
        {:ok, res} ->
          case Jason.decode(res.body) do
            {:ok, resj} ->
              resj["results"] |> Enum.map(fn item -> item["IP"] end)
          end

        {:error, error} ->
          Logger.warning("failed to fetch iperf servers;#{inspect(error)}")
          []
      end

    Logger.info("got following servers\n#{inspect(result)}")
    result
  end

  def upload(server_id, duration) do
    cmd = "iperf3 -c #{server_id} --zerocopy --time #{(duration / 1_000) |> round()} --version4"
    Logger.info(cmd)

    if(Application.get_env(:hava, Uploader)[:enabled]) do
      {:ok, result} =
        CmdWrapper.run(
          cmd,
          duration + @call_timeout
        )

      scan = Regex.scan(~r/^\s*\[\s*\d+\].+(\d+\.\d+)\s+Mbits\/sec.+sender$/m, result)
      if(length(scan) > 0) do
        scan
        |> hd()
        |> Enum.at(1)
        |> Float.parse()
        |> elem(0)
      else
        0
      end
    else
      # this is just placed for dev and manually testing
      Logger.warning("skipping upload as it is disabled in config")
      10
    end
  end
end
