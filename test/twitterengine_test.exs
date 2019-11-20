defmodule TwitterengineTest do
  use ExUnit.Case, async: true
  

  setup do
    #tweeter_server = start_supervised!(TwitterEngine.Server)
    #tweeter_client_1 = start_supervised!(TwitterEngine.Client, [1, 2, 2])
    # children = [
    #   worker(TwitterEngine.Server, ['abc'], id: "server") | 
    #   Enum.map(1..clients, fn n -> 
    #     worker(TwitterEngine.Client, [n, messages, clients], id: "worker_client_#{n}" ) 
    #   end)
    # ]
    # tweeter_server = start_supervised(TwitterEngine.Server)
    # tweeter_client = start_supervised({TwitterEngine.Client, [1, 2, 2]})

    {:ok, tweeter_server} = start_supervised(TwitterEngine.Server)
    {:ok, tweeter_client} = start_supervised({TwitterEngine.Client, {1, 2, 2}})

    #tweeter_server = start_supervised!(children)
    %{server: tweeter_server, client: tweeter_client}
    #%{everything: tweeter_server}
  end

  test "Let's check registration", %{server: tweeter_server, client: tweeter_client} do
    assert :ets.lookup(:tab_user, 1) == []

    IO.inspect tweeter_client

    _ = GenServer.call(:client_1, {:register})



    #tweeter_client.register_self()
    #IO.inspect tweeter_client
    assert [{1, [], [], "connected", []}] = :ets.lookup(:tab_user, 1)
    
  end

end
