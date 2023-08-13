defmodule Hava.Uploader do
  @callback get_servers() :: [binary]
  @callback upload(binary, integer) :: float

  def get_servers(), do: impl().get_servers()
  def upload(server_id, duration), do: impl().upload(server_id, duration)
  defp impl, do: Application.get_env(:hava, Uploader, :libre_st_uploader)
end
