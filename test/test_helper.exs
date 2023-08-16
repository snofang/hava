ExUnit.start()

require Logger
import Mox

Mox.defmock(Hava.CmdWrapperMock, for: Hava.CmdWrapper)
Application.put_env(:hava, :cmd_wrapper, Hava.CmdWrapperMock)

Mox.defmock(Hava.UploaderMock, for: Hava.Uploader)
Application.put_env(:hava, :uploader, Hava.UploaderMock)

Hava.UploaderMock
|> expect(:upload, fn server_id, duration ->
  Logger.info("mock uploading from server_id: #{server_id}, by duration: #{duration}")
  (:rand.normal() * (140 - 8) + 8) |> Float.round(2)
end)

defmock(Hava.StatsMock, for: Hava.Stats)
Application.put_env(:hava, :stats, Hava.StatsMock)

Hava.StatsMock
|> expect(:read, fn _interface ->
  Logger.info("mock reading stats: no change")
  %{send: 0, receive: 0}
end)
