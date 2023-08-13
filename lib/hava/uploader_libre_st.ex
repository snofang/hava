defmodule Hava.UploaderLibreSt do
  alias Hava.CmdWrapper
  @behaviour Hava.Uploader

  @doc """
  Fetchs available server ids 
  """
  @spec get_servers() :: [binary]
  def get_servers() do
    {:ok, result} = CmdWrapper.run("librespeed-cli --list")

    Regex.scan(~r/^(\d+):/m, result)
    |> Enum.map(&Enum.at(&1, 1))
  end

  def upload(server_id, duration) do
    {:ok, result} = CmdWrapper.run(
      "librespeed-cli --no-download --simple --no-icmp --duration #{duration} --server #{server_id}")
    Regex.scan(~r/^Upload rate:\t(\d*\.*\d*) Mbps/m, result) 
    |> hd() 
    |> Enum.at(1) 
    |> Float.parse 
    |> elem(0)
  end
end
