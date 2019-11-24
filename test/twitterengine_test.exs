defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server,{"twitterServer"}})
    client_1_pid = start_supervised!({TwitterEngine.Client,{1,2,2}}, id: "client_1")
    client_2_pid = start_supervised!({TwitterEngine.Client,{2,2,2}}, id: "client_2")
    clients = [client_1_pid, client_2_pid]
    %{server: server_pid,clients: clients}
  end


  #====================  REGISTRATION TESTING =========================#
  test "Registration", %{server: server_pid,clients: clients} do

    assert [] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    #IO.inspect :ets.lookup(:tab_user, 1)

    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
  end


  #====================  DELETE ACCOUNT TESTING =========================#
  test "De-Registration", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:deRegister})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [] =:ets.lookup(:tab_user, 1)
  end


  #====================  TWEET TESTING =========================#
  test "Tweet", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    assert []=:ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients,0),{:tweet,["foo", "bar"], 0})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    contains = Enum.member?(["foo", "bar"],elem(Enum.at(:ets.tab2list(:tab_tweet),0),2))
    assert  contains=true
  end

  #====================  HASHTAG TESTING =========================#
  test "DoubleHashTag", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients,0),{:tweet,["#COP5615 is #great"], 0})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)

    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

 #====================  MENTIONS TESTING =========================#
  test "DoubleMentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients,0),{:tweet,["@pranav is @hero"], 0})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [{"@pranav", _}] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end

  #====================  QUERY TWEETS WITH HASHTAG TESTING =========================#
  test "Query-tweets with specific hashtags", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients,0),{:tweet,["@subham and @pranav are #hero"],0})
    GenServer.cast(Enum.at(clients,0),{:tweet,["@AlinDobra is #hero"],0})
    GenServer.cast(Enum.at(clients,0),{:tweet,["#DOS is #great"],0})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert ["@AlinDobra is #hero","@subham and @pranav are #hero"] == GenServer.call(Enum.at(clients,0),{:queryHashTags,"#hero"})
  end

  #====================  QUERY TWEETS WITH MY MENTIONS =========================#
  test "Query-tweets with my mentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_mentions)

    clientName = "@"<>Atom.to_string(elem(:erlang.process_info(Enum.at(clients,0),:registered_name),1))
    GenServer.cast(Enum.at(clients,0),{:tweet,[clientName<>" is #champion"],0})
    GenServer.cast(Enum.at(clients,0),{:tweet,[clientName<>" is #hero"],0})
    GenServer.cast(Enum.at(clients,0),{:tweet,["@AlinDobra is #great"],0})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    IO.inspect ["hehe", :ets.match_object(:tab_tweet, {:"_", 1, :"_"})]
    IO.inspect [ "haha", GenServer.call(Enum.at(clients,0),{:queryMyMention,clientName})]
    assert  [clientName<>" is #hero",clientName<>" is #champion"] == GenServer.call(Enum.at(clients,0),{:queryMyMention,clientName})
  end


  #====================  SUBSCRIBER TESTING =========================#
  test "Subscribe",  %{server: server_pid,clients: clients} do
    assert [] = :ets.lookup(:tab_user, 1)
    assert [] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients,0),{:register})
    GenServer.cast(Enum.at(clients,1),{:register})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, [2]})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)
  end

  #====================  RETWEET AND SUBSCRIBED USER RECEIVING MESSAGE TESTING =========================#
  test "Retweet and Subscribed user receiving message",  %{server: server_pid,clients: clients} do
   GenServer.cast(Enum.at(clients,0),{:register})
   GenServer.cast(Enum.at(clients,1),{:register})
   :sys.get_state(Enum.at(clients,0))
   :sys.get_state(Enum.at(clients,1))
   :sys.get_state(server_pid)

   GenServer.cast(Enum.at(clients,0),{:subscribe, [2]})
   :sys.get_state(Enum.at(clients,0))
   :sys.get_state(Enum.at(clients,1))
   :sys.get_state(server_pid)

   GenServer.cast(Enum.at(clients,1),{:tweet,["foo", "bar"], 1})
   :sys.get_state(Enum.at(clients,1))
   :sys.get_state(Enum.at(clients,0))
   :sys.get_state(server_pid)

   :sys.get_state(Enum.at(clients,1))
   :sys.get_state(Enum.at(clients,0))
   :sys.get_state(server_pid)

   { _, _, client1_retweet} = Enum.at(:ets.match_object(:tab_tweet, {:"_", 1, :"_"}),0)
   { _, _, client2_tweet} = Enum.at(:ets.match_object(:tab_tweet, {:"_", 2, :"_"}),0)
   assert  client2_tweet == String.slice(client1_retweet,0..-28)
  end



  #====================  QUERY TWEETS SUBSCRIBED TO =========================#
  test "Query-tweets subscribed to", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    GenServer.cast(Enum.at(clients,1),{:register})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, [2]})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

	  #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients,1),{:tweet,["#tweet from 2"],0})
    GenServer.cast(Enum.at(clients,0),{:tweet,["#tweet from 1"],0})
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert ["#tweet from 2"] = GenServer.call(Enum.at(clients,0),{:allSubscribedTweets})
	end

  #====================  LIVE TWEETS TEST (if user is subscried) =========================#
  test "Live-tweets test", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register})
    GenServer.cast(Enum.at(clients,1),{:register})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, [2]})
	  :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

	  #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    pid = Enum.at(clients,0)
    :erlang.trace(pid, true, [:receive])

    GenServer.cast(Enum.at(clients,1),{:tweet,["#tweet from 2"],0})
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast",{:on_the_feed,2,"#tweet from 2",_}}}
	end

end
