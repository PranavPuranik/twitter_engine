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
                     messages + (messages * 20)

                 id <= (clients*0.1) ->
                     messages + (messages * 10)

                 id <= (clients*0.6) ->
                     messages + (messages * 2)

                 true ->
                     messages + 1
              end
    already_sent = 0
    {:ok, {id, already_sent, messages, clients}}
  end

  def handle_cast({:register},{id, already_sent, messages, clients}) do
    GenServer.cast(:twitterServer,{:registerUser,id})
    {:noreply, {id, already_sent, messages, clients}}
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

  def handle_cast({:deRegister},{id, already_sent, messages, clients}) do
    GenServer.cast(:twitterServer,{:deRegisterUser,id})
    {:noreply, {id, already_sent, messages, clients}}
  end

  def handle_cast({:tweet,tweet_pool, retweet_testing},{id, already_sent, messages, clients}) do
    #IO.puts "#{id} tweeting #{already_sent} / #{messages}"
    msg = Enum.random(tweet_pool)
    tweetId = if retweet_testing == 0 do
                GenServer.cast(:twitterServer,{:tweet,id,msg, 0})
              else
                GenServer.cast(:twitterServer,{:tweet,id,msg, 1})
              end
    {:noreply, {id, already_sent + 1, messages, clients}}
  end

  def handle_call({:queryHashTags,hashTag},_from,{id, already_sent, messages, clients}) do
    tweets=GenServer.call(:twitterServer,{:queryHashTags,hashTag}, :infinity)
    {:reply,tweets, {id, already_sent, messages, clients}}
  end

  def handle_call({:queryMyMention,mention},_from,{id, already_sent, messages, clients}) do
    tweets= GenServer.call(:twitterServer,{:queryMyMention,mention}, :infinity)
    {:reply, tweets,{id, already_sent, messages, clients}}
  end

  def handle_cast({:subscribe, subscribe_to},{id, already_sent, messages, clients})do
    #IO.inspect [id, subscribe_to]
    GenServer.cast(:twitterServer,{:subscribe,id,subscribe_to})
    {:noreply, {id, already_sent, messages, clients}}
  end

  def handle_call({:allSubscribedTweets},_from,{id, already_sent, messages, clients})do
    tweets = GenServer.call(:twitterServer,{:allSubscribedTweets,id}, :infinity)
    {:reply,tweets,{id, already_sent, messages, clients}}
  end

  def handle_cast({:on_the_feed, tweet_by,message, chance},{id, already_sent, messages, clients})do
    #IO.puts "user#{id} received a tweet from user:#{tweet_by}:: #{message} #{chance}"
    chance =  if chance != 1 do
                100
              else
                1
              end
    if :rand.uniform(chance) == 1 and already_sent <= messages do
      retweet =   if (Regex.match?(~r/Retweeted from/ , message)) do
                      message
                  else
                      message <> " - Retweeted from source #{tweet_by}."
                  end
      #IO.puts "Retweeting: "<>retweet
      GenServer.cast(:twitterServer,{:tweet,id,retweet, 0})
    end
    {:noreply,{id, already_sent, messages, clients}}
  end

  def handle_cast({:simulate,tweet_pool},{id, already_sent, messages, clients}) do
    #   if(current_state < numMsg && elem(Enum.at(:ets.lookup(:tweet_counter,"count"),0),1)<numMsg) do
    #     GenServer.cast(self(),{:tweet,tweet_pool,0})
    #     GenServer.cast(self(),{:simulate,current_state+1,numMsg,tweet_pool})
    #   else
    #     IO.inspect ["User #{id} done with #{messages}!!", :ets.lookup(:tab_user, id)], charlists: :as_lists
    #   end
    # {:noreply,{id, already_sent, messages, clients}}
    


    if(already_sent <= messages) do
      choice = :rand.uniform(20)
      #IO.puts "#{id} simulate #{choice}"
      case choice do
          1 ->
              
              connect_disconnect(id)
              

          2 ->
              mention = "@client_"<>Integer.to_string(id)
              results = GenServer.call(:twitterServer,{:queryMyMention,mention}, :infinity)
              

          3 ->
              hashtag = "#some_hashtag_" <>Integer.to_string(:rand.uniform(9))
              results = GenServer.call(:twitterServer,{:queryHashTags,hashtag}, :infinity)

          4 ->
              msg = Enum.random(tweet_pool) <> " @client_"<>Integer.to_string(:rand.uniform(clients))
              GenServer.cast(self(),{:tweet,[msg], 0})

          5 ->
              msg = Enum.random(tweet_pool) <> " #some_hashtag_" <>Integer.to_string(:rand.uniform(9))
              GenServer.cast(self(),{:tweet,[msg], 0})

          _ ->
              
              GenServer.cast(self(),{:tweet,tweet_pool, 0})
              #querytweets(x)

      end
      #Process.sleep (:rand.uniform(100))
      #IO.puts "client #{x} act #{acts}"
      GenServer.cast(self(),{:simulate,tweet_pool})
      
    else
      IO.puts "Client #{id} completed #{messages} tweets."
      #GenServer.cast(:orc, {:acts_completed})
    end
    {:noreply,{id, already_sent, messages, clients}}
  end

  def connect_disconnect(id)do
      #stop all activities, play dead
      #inform server
      time = Enum.random(30..50)
      GenServer.cast(:twitterServer,{:disconnection,id})
      Process.sleep(time)
      GenServer.cast(:twitterServer,{:reconnection,id})
  end

end
