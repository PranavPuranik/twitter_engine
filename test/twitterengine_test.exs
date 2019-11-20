defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server,["abc"]})
    client_pid = start_supervised!({TwitterEngine.Client,{1,2,2}})
    %{server: server_pid,client: client_pid}
  end

  test "Registration", %{server: server_pid,client: client_pid} do
    assert [] =:ets.lookup(:tab_user, 1)

    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)
  end

  test "DeRegistration", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)

    GenServer.cast(client_pid,{:deRegister,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert [] =:ets.lookup(:tab_user, 1)
  end

  test "Tweet", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["foo", "bar"]})
    contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
    assert  contains=true
  end

  test "HashTag", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["#COP5615 is great"]})
    #IO.inspect :ets.tab2list(:tab_mentions)
    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
  end

  test "DoubleHashTag", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["#COP5615 is #great"]})
    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

  test "Mentions", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["i am @bestuser"]})
    #IO.inspect :ets.tab2list(:tab_mentions)
    assert [{"@bestuser", _}] = :ets.lookup(:tab_mentions, "@bestuser")
  end

  test "DoubleMentions", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(client_pid,{:tweet,server_pid,["@pranav is @hero"]})
    #IO.inspect :ets.tab2list(:tab_mentions)
    assert [{"@pranav", _}] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end

  test "Query-tweets with specific hashtags", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetIdsWithHashHero = []
    tweetIdsWithoutHashHero = []
    tweetIdsWithHashHero ++ [GenServer.call(client_pid,{:tweet,server_pid,["@pranav is #hero"]})]
    tweetIdsWithHashHero ++ [GenServer.call(client_pid,{:tweet,server_pid,["@AlinDobra is #hero"]})]
    tweetIdsWithoutHashHero ++ [GenServer.call(client_pid,{:tweet,server_pid,["#DOS is #great"]})]
    assert tweetIdsWithoutHashHero = elem(Enum.at(:ets.lookup(:tab_hashtag, "#hero"),0),1)
  end

  test "Query-tweets with specific mentions", %{server: server_pid,client: client_pid} do
    GenServer.cast(client_pid,{:register,server_pid})
    :sys.get_state(client_pid)
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_mentions)

    tweetIdsWithMentionPranav = []
    tweetIdsWithoutMentionPranav = []
    tweetIdsWithMentionPranav ++ [GenServer.call(client_pid,{:tweet,server_pid,["@pranav is #champion"]})]
    tweetIdsWithMentionPranav ++ [GenServer.call(client_pid,{:tweet,server_pid,["@pranav is #hero"]})]
    tweetIdsWithoutMentionPranav ++ [GenServer.call(client_pid,{:tweet,server_pid,["@AlinDobra is #great"]})]
    assert tweetIdsWithMentionPranav = elem(Enum.at(:ets.lookup(:tab_mentions, "@pranav"),0),1)
  end

end
