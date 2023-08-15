defmodule Hava.CmdWrapper do
  @moduledoc """
  This is a simple wrapper around special commands
    *- which does not have space in their tockes
    *- and also have their output in stderr 
  caution: it is not intended for general purpose usage
  """
  @callback run(binary, non_neg_integer) :: binary

  def run(cmd, timeout \\ 5_000), do: impl().run(cmd, timeout)
  defp impl, do: Application.get_env(:hava, :cmd_wrapper)
end
