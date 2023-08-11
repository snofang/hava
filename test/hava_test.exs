defmodule HavaTest do
  use ExUnit.Case
  doctest Hava

  test "greets the world" do
    assert Hava.hello() == :world
  end
end
