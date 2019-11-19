defmodule TwitterengineTest do
  use ExUnit.Case
  doctest Twitterengine

  test "greets the world" do
    assert Twitterengine.hello() == :world
  end
end
