defmodule Hava.Uploader do
  @callback get_servers() :: [binary]
  @callback upload(binary, non_neg_integer) :: float

  def get_servers(), do: impl().get_servers()
  def upload(server_id, duration), do: impl().upload(server_id, duration)
  defp impl, do: Application.get_env(:hava, :uploader, :libre_st_uploader)
end
