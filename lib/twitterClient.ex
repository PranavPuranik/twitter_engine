defmodule TwitterEngine.Client do
  use GenServer

  # Initialization
  def start_link({id, messages, clients}) do
    GenServer.start_link(__MODULE__, {id, messages, clients}, name: String.to_atom("client_#{id}"))
  end

  def init({id, messages, clients}) do

    #ZIPF - considering the clients with starting ids have more subscribers
    messages = cond do
                 id <= (clients*0.01) ->
                     messages * 20

                 id <= (clients*0.1) ->
                     messages * 10

                 id <= (clients*0.6) ->
                     messages * 2

                 true ->
                     messages
              end

    {:ok, {id, messages, clients}}
  end

  def handle_cast({:register},{id, messages, clients}) do
    GenServer.cast(:twitterServer,{:registerUser,id})
    {:noreply, {id, messages, clients}}
  end


  # def handle_cast({:action,current_state},{x,acts,servernode,clients,tweets_pool}) do
  #     if(current_state < acts) do
  #         choice = rem(:rand.uniform(999999),14)
  #         case choice do
  #             1 ->
  #                 #subscribe(x,servernode,clients)
  #                 tweet_hash(x,servernode,tweets_pool,clients)

  #             2 ->
  #                 tweet_mention(x,servernode,tweets_pool,clients)

  #             3 ->
  #                 queryhashtags(x,servernode)

  #             4 ->
  #                 query_self_mentions(x,servernode)

  #             5 ->
  #                 discon(x,servernode)

  #             _ ->
  #                 tweet(x,servernode,tweets_pool)
  #                 #querytweets(x)

  #         end
  #         #Process.sleep (:rand.uniform(100))
  #         #IO.puts "client #{x} act #{acts}"
  #         GenServer.cast(self(),{:action,current_state + 1})
  #     else
  #         IO.puts "User #{x} has finised generating at least #{acts} activities (Tweets/Queries)."
  #         GenServer.cast(:orc, {:acts_completed})
  #     end
  #     {:noreply,{x,acts,servernode,clients,tweets_pool}}
  #   end

  def handle_cast({:deRegister},{id, messages, clients}) do
    GenServer.cast(:twitterServer,{:deRegisterUser,id})
    {:noreply, {id, messages, clients}}
  end

  def handle_cast({:tweet,tweet_pool, retweet_testing},{id, messages, clients}) do
    msg = Enum.random(tweet_pool)
    tweetId = if retweet_testing == 0 do
      GenServer.cast(:twitterServer,{:tweet,id,msg, 0})
    else
      GenServer.cast(:twitterServer,{:tweet,id,msg, 1})
    end
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:queryHashTags,hashTag},_from,{id, messages, clients}) do
    tweets=GenServer.call(:twitterServer,{:queryHashTags,hashTag})
    {:reply,tweets, {id, messages, clients}}
  end

  def handle_call({:queryMyMention,mention},_from,{id, messages, clients}) do
    tweets= GenServer.call(:twitterServer,{:queryMyMention,mention})
    {:reply, tweets,{id, messages, clients}}
  end

  def handle_cast({:subscribe, subscribe_to},{id, messages, clients})do
    #IO.inspect [id, subscribe_to]
    GenServer.cast(:twitterServer,{:subscribe,id,subscribe_to})
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:allSubscribedTweets},_from,{id, messages, clients})do
    tweets = GenServer.call(:twitterServer,{:allSubscribedTweets,id})
    {:reply,tweets,{id, messages, clients}}
  end

  def handle_cast({:on_the_feed, tweet_by,message, chance},{id, messages, clients})do
    #IO.puts "user#{id} received a tweet from user:#{tweet_by}:: #{message} #{chance}"
    chance =  if chance != 1 do
                100
              else
                1
              end
    if (:rand.uniform(chance) == 1) do
      retweet =   if (Regex.match?(~r/Retweeted from/ , message)) do
                      message
                  else
                      message <> " - Retweeted from source #{tweet_by}."
                  end
      #IO.puts "Retweeting: "<>retweet
      GenServer.cast(:twitterServer,{:tweet,id,retweet, 0})
    end
    {:noreply,{id, messages, clients}}
  end

  def handle_cast({:simulate,current_state,numMsg,tweet_pool},{id, messages, clients}) do
        if(current_state < numMsg && elem(Enum.at(:ets.lookup(:tweet_counter,"count"),0),1)<numMsg) do
          GenServer.cast(self(),{:tweet,tweet_pool,0})
          GenServer.cast(self(),{:simulate,current_state+1,numMsg,tweet_pool})
        else
          IO.inspect ["User #{id} done with #{messages}!!", :ets.lookup(:tab_user, id)], charlists: :as_lists
        end
      {:noreply,{id, messages, clients}}
    end


end
