defmodule Hava.StatsDev do
  require Logger
  alias Hava.CmdWrapper
  alias Hava.Stats

  @behaviour Stats

  def read(interface) do
    {:ok, result} = CmdWrapper.run("cat /proc/net/dev")

    case Regex.run(~r/^\s*#{interface}:.*$/m, result) do
      nil ->
        msg = "failed to read stats for #{interface} in /proc/net/dev."
        Logger.error(msg)
        raise(msg)

      match ->
        tockens =
          match
          |> List.first()
          |> String.split()

        %{
          receive: Enum.at(tockens, 1) |> Integer.parse() |> elem(0),
          send: Enum.at(tockens, 9) |> Integer.parse() |> elem(0)
        }
    end
  end
end
