defmodule Hava.UsageStats do
  @doc """
  Reads network usage for interface(e.g wlp3s0) using /proc/net/dev and returns 
  only send and receive in bytes
  """
  @spec read(binary()) :: %{receive: integer(), send: integer()}
  def read(interface) do
    {result, 0} = System.shell("cat /proc/net/dev")
    tockens = Regex.run(~r/#{interface}:.*/m, result) |> List.first() |> String.split()

    %{
      receive: Enum.at(tockens, 1) |> Integer.parse() |> elem(0),
      send: Enum.at(tockens, 9) |> Integer.parse() |> elem(0)
    }
  end
end
