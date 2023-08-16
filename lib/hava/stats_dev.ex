defmodule Hava.StatsDev do
  alias Hava.CmdWrapper
  alias Hava.Stats
   
  @behaviour Stats
  
  def read(interface) do
    {:ok, result} = CmdWrapper.run("cat /proc/net/dev")
      # System.shell("cat /proc/net/dev")
    tockens = Regex.run(~r/#{interface}:.*/, result) |> List.first() |> String.split()

    %{
      receive: Enum.at(tockens, 1) |> Integer.parse() |> elem(0)|> to_mbit(),
      send: Enum.at(tockens, 9) |> Integer.parse() |> elem(0) |> to_mbit()
    }
  end
  
  def to_mbit(bytes), do: bytes/1024/1024*8 |> trunc()
end
