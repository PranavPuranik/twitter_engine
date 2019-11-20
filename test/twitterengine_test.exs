defmodule TwitterengineTest do
  use ExUnit.Case, async: true
  doctest Twitterengine

  setup do
    tweeter_server = start_supervised!(TwitterEngine.Server)
    %{server: tweeter_server}
  end

  test "Let's check registration", %{server: tweeter_server} do
    assert :ets.lookup(:tab_user, "client_1") == []

    Genserver.cast(:client_1, {:register})
    assert [{"1", [], [], "connected", []}] = :ets.lookup(:tab_user, "client_1")
    
  end

end
