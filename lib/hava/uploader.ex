defmodule Hava.Uploader do
  require Logger
  @callback get_servers() :: [binary]
  @callback upload(binary, non_neg_integer) :: float

  def get_servers(), do: impl().get_servers()

  def upload(server_id, duration) do
    if(Application.get_env(:hava, Uploader)[:enabled]) do
      impl().upload(server_id, duration)
    else
      Logger.warn("""
      real uploading is disabled; skipping ...
      Please enable it in config via: `:hava, Uploader, enabled: true`
      """)
    end
  end

  defp impl, do: Application.get_env(:hava, :uploader, :libre_st_uploader)
end
