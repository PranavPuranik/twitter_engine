defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server,["abc"]})
    client_pid = start_supervised!({TwitterEngine.Client,{1,2,2}})
    %{server: server_pid,client: client_pid}
  end

  test "Registration", %{server: server_pid,client: client_pid} do
    assert [] =:ets.lookup(:tab_user, 1)

    GenServer.call(client_pid,{:register,server_pid})
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)
  end

  test "De-Registration", %{server: server_pid,client: client_pid} do
    GenServer.call(client_pid,{:register,server_pid})
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)

    GenServer.call(client_pid,{:deRegister,server_pid})
    assert [] =:ets.lookup(:tab_user, 1)
  end

  test "Tweet", %{server: server_pid,client: client_pid} do
    GenServer.call(client_pid,{:register,server_pid})
    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["foo", "bar"]})
    contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
    assert  contains=true
  end


end
