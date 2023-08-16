defmodule Hava.Stats do
  @doc """
  Reads network usage for interface(e.g wlp3s0) using /proc/net/dev and returns 
  only send and receive in bytes
  """
  @callback read(binary()) :: %{receive: integer(), send: integer()}


  def read(interface), do: impl().read(interface)
  def impl, do: Application.get_env(:hava, :stats)
end
