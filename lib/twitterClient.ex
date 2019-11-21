defmodule TwitterEngine.Client do
  use GenServer

  # Initialization
  def start_link({id, messages, clients}) do
    GenServer.start_link(__MODULE__, {id, messages, clients}, name: String.to_atom("client_#{id}"))
  end

  def init({id, messages, clients}) do
    {:ok, {id, messages, clients}}
  end

  def handle_cast({:register},{id, messages, clients}) do
    GenServer.cast(:twitterServer,{:registerUser,id})
    GenServer.cast(:main,{:registered})
    {:noreply, {id, messages, clients}}
  end

  def handle_cast({:deRegister},{id, messages, clients}) do
    GenServer.cast(:twitterServer,{:deRegisterUser,id})
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:tweet,tweet_pool, retweet_testing}, _from,{id, messages, clients}) do
    msg = Enum.random(tweet_pool)
    tweetId = if retweet_testing == 0 do
      GenServer.call(:twitterServer,{:tweet,id,msg, 0})
    else
      GenServer.call(:twitterServer,{:tweet,id,msg, 1})
    end
    {:reply,tweetId, {id, messages, clients}}
  end

  def handle_call({:queryHashTags,hashTag},_from,{id, messages, clients}) do
    tweets = GenServer.call(:twitterServer,{:queryHashTags,hashTag})
    {:reply,tweets, {id, messages, clients}}
  end

  def handle_call({:queryMyMention,mention},_from,{id, messages, clients}) do
    tweets = GenServer.call(:twitterServer,{:queryMyMention,mention})
    {:reply,tweets, {id, messages, clients}}
  end

  def handle_cast({:subscribe, subscribe_to},{id, messages, clients})do
    GenServer.cast(:twitterServer,{:subscribe,id,subscribe_to})
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:allSubscribedTweets},_from,{id, messages, clients})do
    tweets = GenServer.call(:twitterServer,{:allSubscribedTweets,id})
    {:reply, tweets,{id, messages, clients}}
  end

  def handle_cast({:on_the_feed, tweet_by,message, chance},{id, messages, clients})do
    IO.puts "user#{id} received a tweet from user#{tweet_by}:: #{messages} #{chance}"
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
      #IO.puts "Retweeting: "<>rt_msg
      tweetId = GenServer.call(:twitterServer,{:tweet,id,retweet, 0})
    end
    {:noreply,{id, messages, clients}}
  end

  def handle_cast({:simulate,current_state,numMsg,tweet_pool},{id, messages, clients}) do
        if(current_state < numMsg && elem(Enum.at(:ets.lookup(:tweet_counter,"count"),0),1)<numMsg) do
          GenServer.call(:tweet,tweet_pool, Enum.random(0))
          GenServer.cast(self(),{:simulate,current_state+1})
        else
          IO.inspect "User #{id} done !!"
        end
      {:noreply,{id, messages, clients}}
    end


end
