defmodule Hava.UploaderLibreSt do
  require Logger
  alias Hava.CmdWrapper
  @behaviour Hava.Uploader
  @libre_call_timeout 20_000

  @doc """
  Fetchs available server ids 
  """
  @spec get_servers() :: [binary]
  def get_servers() do
    {:ok, result} = CmdWrapper.run("librespeed-cli --list", @libre_call_timeout)
    Logger.info("got following servers\n#{inspect(result)}")

    Regex.scan(~r/^(\d+):/m, result)
    |> Enum.map(&Enum.at(&1, 1))
  end

  def upload(server_id, duration) do

    cmd =
      "librespeed-cli --no-download --simple --no-icmp --duration #{duration/1_000 |> round()} --server #{server_id}"

    Logger.info(cmd)

    if(Application.get_env(:hava, Uploader)[:enabled]) do
      {:ok, result} =
        CmdWrapper.run(
          cmd,
          duration + @libre_call_timeout
        )

      scan = Regex.scan(~r/Upload rate:\s+(\d*\.*\d*)\s+Mbps/, result)

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
