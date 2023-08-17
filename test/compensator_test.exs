defmodule CompensatorTest do
  use ExUnit.Case, async: true
  # import Mox
  # setup :set_mox_from_context
  # setup :verify_on_exit!

  test "test proper dispatch in compensator" do
    Application.put_env(:hava, :uploader, Hava.UploaderMockServer)
    start_supervised!(Hava.UploaderMockServer)
    start_supervised!(Hava.Compensator)
    Hava.Compensator.compensate(200 * 8, 10_000)
    :timer.sleep(1_000)
    IO.inspect(Hava.UploaderMockServer.get_called_servers()) 
  end
end
