defmodule Hava.UploaderLibreSt do
  alias Hava.CmdWrapper
  @behaviour Hava.Uploader
  @libre_call_timeout 20_000

  @doc """
  Fetchs available server ids 
  """
  @spec get_servers() :: [binary]
  def get_servers() do
    {:ok, result} = CmdWrapper.run("librespeed-cli --list", @libre_call_timeout)

    Regex.scan(~r/^(\d+):/m, result)
    |> Enum.map(&Enum.at(&1, 1))
  end

  def upload(server_id, duration) do
    {:ok, result} =
      CmdWrapper.run(
        "librespeed-cli --no-download --simple --no-icmp --duration #{duration} --server #{server_id}",
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
  end
end
