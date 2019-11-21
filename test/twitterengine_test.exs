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

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["foo", "bar"], 0})
    contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
    assert  contains=true
  end

  #====================  HASHTAG TESTING =========================#
  test "DoubleHashTag", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["#COP5615 is #great"], 0})
    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

 #====================  MENTIONS TESTING =========================#
  test "DoubleMentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is @hero"], 0})
    #IO.inspect :ets.tab2list(:tab_mentions)
    assert [{"@pranav", _}] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end

  #====================  QUERY TWEETS WITH HASHTAG TESTING =========================#
  test "Query-tweets with specific hashtags", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is #hero"]})
    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@AlinDobra is #hero"]})
    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["#DOS is #great"]})
    assert ["@AlinDobra is #hero","@pranav is #hero"] == GenServer.call(Enum.at(clients,0),{:queryHashTags,server_pid,"#hero"})
  end

  #====================  QUERY TWEETS WITH MY MENTIONS =========================#
  test "Query-tweets with specific mentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_mentions)

    clientName = "@"<>Atom.to_string(elem(:erlang.process_info(Enum.at(clients,0),:registered_name),1))
    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,[clientName<>" is #champion"]})
    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,[clientName<>" is #hero"]})
    GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@AlinDobra is #great"]})
    assert  [clientName<>" is #hero",clientName<>" is #champion"] == GenServer.call(Enum.at(clients,0),{:queryMyMention,server_pid,clientName})
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

  #====================  RETWEET AND SUBSCRIBED USER RECEIVING MESSAGE TESTING =========================#
 # test "Retweet and Subscribed user receiving message",  %{server: server_pid,clients: clients} do
 #   GenServer.cast(Enum.at(clients,0),{:register,server_pid})
 #   GenServer.cast(Enum.at(clients,11),{:register,server_pid})
 #
 #   #assert []=:ets.tab2list(:tab_tweet)
 #
 #   :sys.get_state(Enum.at(clients,0))
 #   :sys.get_state(Enum.at(clients,1))
 #   :sys.get_state(server_pid)
 #
 #   GenServer.cast(Enum.at(clients,0),{:subscribe, server_pid, [2]})
 #
 #   #IO.inspect Process.alive?(Enum.at(clients,1))
 #   :sys.get_state(Enum.at(clients,0))
 #   :sys.get_state(Enum.at(clients,1))
 #   :sys.get_state(server_pid)
 #
 #   tweetId = GenServer.call(Enum.at(clients,1),{:tweet,server_pid,["foo", "bar"], 1})
 #
 #   IO.inspect :ets.match_object(:tab_tweet, {:"_", 2, :"_"})
 #
 #
 #
 #   #contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
 #   assert  contains=true
 # end



  #====================  QUERY TWEETS SUBSCRIBED TO =========================#
  test "Query-tweets subscribed to", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    GenServer.cast(Enum.at(clients,1),{:register,server_pid})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, server_pid, [2]})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

	  #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    #Atom.to_string(elem(:erlang.process_info(Enum.at(clients,0),:registered_name),1))
    GenServer.call(Enum.at(clients,1),{:tweet,server_pid,["#tweet from 2"]})
    GenServer.call(Enum.at(clients,0),{:allSubscribedTweets,server_pid})
	end


end
