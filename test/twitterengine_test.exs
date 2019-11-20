defmodule TwitterengineTest do
  use ExUnit.Case, async: true
  doctest Twitterengine

  setup do
    tweeter_server = start_supervised!(TwitterServer)
    %{server: tweeter_server}
  end

  test "Let's check registration", %{server: tweeter_server} do
    assert TwitterServer.lookup(registry, "client-1") == []

    Genserver.cast(:client-1, {:register})
    assert [{"1", [], [], "connected", []}] = TwitterServer.lookup(registry, "client-1")
    
  end

end
