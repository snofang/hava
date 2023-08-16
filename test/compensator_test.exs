defmodule CompensatorTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!
  
  setup %{} do
    %{servers: 1..10 |> Enum.map(&to_string/1), speeds: 1..10}
  end

  test "test proper server dispatch in compensator", %{servers: servers} do
    Hava.UploaderMock
    |> expect(:get_servers, fn -> servers end)

    # |> expect(upload, fn(, _duration) -> 11 end)

    assert Hava.Uploader.get_servers() == servers
  end
end
