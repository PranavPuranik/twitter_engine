defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server, {"twitterServer", 10}})
    client_1_pid = start_supervised!({TwitterEngine.Client, {1, 2, 2}}, id: "client_1")
    client_2_pid = start_supervised!({TwitterEngine.Client, {2, 2, 2}}, id: "client_2")
    clients = [client_1_pid, client_2_pid]
    %{server: server_pid, clients: clients}
  end

  # ====================  TEST CASE #1: REGISTRATION TESTING =========================#
  test "Registration", %{server: server_pid, clients: clients} do
    assert [] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    # IO.inspect :ets.lookup(:tab_user, 1)

    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
  end

  # ====================  TEST CASE #2: RE_REGISTRATION TESTING =========================#
  test "Re-Registration", %{server: server_pid, clients: clients} do
    assert [] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)

    pid = Enum.at(clients, 0)
    :erlang.trace(pid, true, [:receive])

    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_cast", {:notification, "account already exists"}}}
  end

  # ====================  TEST CASE #3: DELETE ACCOUNT TESTING =========================#
  test "De-Registration", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients, 0), {:deleteAccount})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.lookup(:tab_user, 1)
  end

  # ====================  TEST CASE #4: TWEET TESTING =========================#
  test "Tweet", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["foo", "bar"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    contains = Enum.member?(["foo", "bar"], elem(Enum.at(:ets.tab2list(:tab_tweet), 0), 2))
    assert contains
  end

  # ==================== TEST CASE #5: SENTIMENTAL ANALYSIS =========================#
  test "Tweet-Sentiment", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@parth love @pranav"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    contains =Enum.member?(["@parth love @pranav"], elem(Enum.at(:ets.tab2list(:tab_tweet), 0), 2))
    assert contains

    pid = Enum.at(clients, 0)
    :erlang.trace(pid, true, [:receive])

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@parth hate @pranav","@pranav hate1 @parth"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    contains = Enum.member?(["@parth hate @pranav"], elem(Enum.at(:ets.tab2list(:tab_tweet), 0), 2))
    assert !contains
    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_cast", {:notification, "this might hurt someone's sentiment"}}}
  end

  # ====================  TEST CASE #6: TWEET FROM USER WITHOUT ACCOUNT TESTING =========================#
  test "Tweet from Unregistered User", %{server: server_pid, clients: clients} do
    
    assert [] = :ets.lookup(:tab_user, 1)
    assert [] = :ets.tab2list(:tab_tweet)


    pid = Enum.at(clients, 0)
    :erlang.trace(pid, true, [:receive])

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["foo", "bar"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_cast", {:notification, "Create an account first!"}}}
    assert [] = :ets.tab2list(:tab_tweet)

  end

  # ====================  TEST CASE #7: HASHTAG TESTING =========================#
  test "DoubleHashTag", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["#COP5615 is #great"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

  # ====================  TEST CASE #8: MY MENTIONS TESTING =========================#
  test "DoubleMentions", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@pranav is @hero"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert [{"@pranav", _}] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end




  # ====================  TEST CASE #9: FINIDING HASHTAG NEVER TWEETED TESTING  =========================#
  # when there isn't any hashtag queried
  test "HashTag2", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["#COP5615 is #great"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert [] = :ets.lookup(:tab_hashtag, "#DOS")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

  # ====================  TEST CASE #10: FINIDING MENTIONS NEVER MENTIONED TESTING =========================#
  # when user has no mentions queried
  test "Mentions2", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["I am is @hero"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert [] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end

  # ====================  TEST CASE #11: HASHTAGS AND MENTIONS BOTH =========================#
  test "Hashtags and Mentions both", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_mentions)

    clientName = "@" <> Atom.to_string(elem(:erlang.process_info(Enum.at(clients, 0), :registered_name), 1))

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@subham is #masterchef"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    # IO.inspect ["hehe", :ets.match_object(:tab_tweet, {:"_", 1, :"_"})]
    # IO.inspect [ "haha", GenServer.call(Enum.at(clients,0),{:queryMyMention,clientName})]
    assert [{"@subham", _}] = :ets.lookup(:tab_mentions, "@subham")
    assert [{"#masterchef", _}] = :ets.lookup(:tab_hashtag, "#masterchef")
  end

  # ====================  TEST CASE #12: QUERY TWEETS WITH HASHTAG =========================#
  test "Query-tweets with specific hashtags", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [] = :ets.tab2list(:tab_tweet)

    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@subham and @pranav are #hero"], 0})
    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@AlinDobra is #hero"], 0})
    GenServer.cast(Enum.at(clients, 0), {:tweet, ["#DOS is #great"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert ["@AlinDobra is #hero", "@subham and @pranav are #hero"] ==
             GenServer.call(Enum.at(clients, 0), {:queryHashTags, "#hero"})
  end


  # ====================  TEST CASE #13: QUERY TWEETS WITH MY MENTIONS =========================#
  test "Query my mentions and hashtags together", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    assert [] = :ets.tab2list(:tab_mentions)

    clientName =
      "@" <> Atom.to_string(elem(:erlang.process_info(Enum.at(clients, 0), :registered_name), 1))

    GenServer.cast(Enum.at(clients, 0), {:tweet, [clientName <> " is #champion"], 0})
    GenServer.cast(Enum.at(clients, 0), {:tweet, [clientName <> " is #hero"], 0})
    GenServer.cast(Enum.at(clients, 0), {:tweet, ["@AlinDobra is #great"], 0})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [clientName <> " is #hero", clientName <> " is #champion"] ==
             GenServer.call(Enum.at(clients, 0), {:queryMyMention, clientName})
  end

  # ====================  TEST CASE #14: SUBSCRIBER TESTING =========================#
  test "Subscribe", %{server: server_pid, clients: clients} do
    assert [] = :ets.lookup(:tab_user, 1)
    assert [] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients, 0), {:register})
    GenServer.cast(Enum.at(clients, 1), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 0), {:subscribe, [2]})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    # adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    # adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)
  end

  # ====================  TEST CASE #15: RETWEET AND SUBSCRIBED USER RECEIVING MESSAGE TESTING =========================#
  test "Retweet and Subscribed user receiving message", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    GenServer.cast(Enum.at(clients, 1), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 0), {:subscribe, [2]})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 1), {:tweet, ["foo", "bar"], 1})
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)

    {_, _, client1_retweet} = Enum.at(:ets.match_object(:tab_tweet, {:_, 1, :_}), 0)
    {_, _, client2_tweet} = Enum.at(:ets.match_object(:tab_tweet, {:_, 2, :_}), 0)
    assert client2_tweet == String.slice(client1_retweet, 0..-28)
  end

  # ====================  TEST CASE #16: QUERY TWEETS FROM USERS SUBSCRIBED TO =========================#
  test "Query-tweets subscribed to", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    GenServer.cast(Enum.at(clients, 1), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 0), {:subscribe, [2]})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    # adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    # adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients, 1), {:tweet, ["#tweet from 2"], 0})
    GenServer.cast(Enum.at(clients, 0), {:tweet, ["#tweet from 1"], 0})
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert ["#tweet from 2"] = GenServer.call(Enum.at(clients, 0), {:allSubscribedTweets})
  end

  # ====================  TEST CASE #17: LIVE TWEETS TEST (if user is subscried) =========================#
  test "Live-tweets test", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    GenServer.cast(Enum.at(clients, 1), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 0), {:subscribe, [2]})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    # adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    # adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    pid = Enum.at(clients, 0)
    :erlang.trace(pid, true, [:receive])

    GenServer.cast(Enum.at(clients, 1), {:tweet, ["#tweet from 2"], 0})
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:on_the_feed, 2, "#tweet from 2", _}}}
  end

  # ====================  TEST CASE #18: LIVE DISCONNECTION AND RECONNECTION (if user is subscried) =========================#
  test "Live-tweets test2", %{server: server_pid, clients: clients} do
    GenServer.cast(Enum.at(clients, 0), {:register})
    GenServer.cast(Enum.at(clients, 1), {:register})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients, 0), {:subscribe, [2]})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    # adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    # adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

    pid = Enum.at(clients, 0)
    :erlang.trace(pid, true, [:receive])
    GenServer.cast(Enum.at(clients, 1), {:tweet, ["#tweet from 2"], 0})
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:on_the_feed, 2, "#tweet from 2", _}}}

    GenServer.cast(Enum.at(clients, 0), {:disconnect})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [{1, [2], [], "disconnected", 0}] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients, 1), {:tweet, ["2nd #tweet from 2"], 0})
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)

    assert [{1, ["2T2"]}] = :ets.lookup(:tab_msgq, 1)

    GenServer.cast(Enum.at(clients, 0), {:reconnect})
    :sys.get_state(Enum.at(clients, 0))
    :sys.get_state(server_pid)
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    
    :sys.get_state(Enum.at(clients, 1))
    :sys.get_state(server_pid)
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:on_the_feed, 2, "2nd #tweet from 2", _}}}

  end
end
