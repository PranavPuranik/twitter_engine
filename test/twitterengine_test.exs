defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server,["abc"]})
    client_1_pid = start_supervised!({TwitterEngine.Client,{1,2,2}}, id: "client_1")
    client_2_pid = start_supervised!({TwitterEngine.Client,{2,2,2}}, id: "client_2")
    clients = [client_1_pid, client_2_pid]
    %{server: server_pid,clients: clients}
  end


  #====================  REGISTRATION TESTING =========================#
  test "Registration", %{server: server_pid,clients: clients} do
    
    assert [] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    #IO.inspect :ets.lookup(:tab_user, 1)

    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
  end


  #====================  DELETE ACCOUNT TESTING =========================#
  test "De-Registration", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:deRegister,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [] =:ets.lookup(:tab_user, 1)
  end


  #====================  TWEET TESTING =========================#
  test "Tweet", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["foo", "bar"]})
    contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
    assert  contains=true
  end

  #====================  TWEET TESTING =========================#
  test "Hash", %{server: server_pid,clients: clients} do
  end

  #====================  SUBSCRIBER TESTING =========================#
  test "Subscribe",  %{server: server_pid,clients: clients} do
    
    assert [] = :ets.lookup(:tab_user, 1)
    assert [] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    GenServer.cast(Enum.at(clients,1),{:register,server_pid})

    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, server_pid, [2]})

    #IO.inspect Process.alive?(Enum.at(clients,1))
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    # IO.inspect ['==>', :ets.lookup(:tab_user, 1)]
    # IO.inspect ['===>', :ets.lookup(:tab_user, 1)]
    # IO.inspect ['==>', :ets.lookup(:tab_user, 2)]
    # IO.inspect ['===>', :ets.lookup(:tab_user, 2)]

    #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

  end


end
