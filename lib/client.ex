defmodule TwitterEngine.Client do
  use GenServer


  # Initialization
  def start_link({id, messages, clients}) do
    GenServer.start_link(__MODULE__, {id, messages, clients}, name: String.to_atom("client_#{id}"))
  end

  def init({id, messages, clients}) do
    {:ok, {id, messages, clients}}
  end

  def handle_cast({:register,server_pid},{id, messages, clients}) do
    GenServer.cast(server_pid,{:registerUser,id})
    {:noreply, {id, messages, clients}}
  end

  def handle_cast({:deRegister,server_pid},{id, messages, clients}) do
    GenServer.cast(server_pid,{:deRegisterUser,id})
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:tweet,server_pid,tweet_pool, retweet_testing}, _from,{id, messages, clients}) do
    msg = Enum.random(tweet_pool)
    tweetId = if retweet_testing == 0 do
      GenServer.call(server_pid,{:tweet, server_pid,id,msg, 0})
    else
      GenServer.call(server_pid,{:tweet, server_pid,id,msg, retweet_testing})
    end
    {:reply,tweetId, {id, messages, clients}}
  end

  def handle_cast({:subscribe, server_pid, subscribe_to},{id, messages, clients})do
    GenServer.cast(server_pid,{:subscribe,id,subscribe_to}) 
    {:noreply, {id, messages, clients}}
  end

  # def handle_cast({:retweet, server_pid, tweet_by, message},{id, messages, clients}) do
  #   retweet =  if (Regex.match?(~r/Retweeted.$/ , msg)) do
  #                 msg
  #             else
  #                 msg <> " - Retweeted by #{id} from #{tweet_by}."
  #             end
  #   tweetId = GenServer.call(server_pid,{:tweet,id,msg})
  #   GenServer.call(server_pid,{:tweet,x,retweet})
  #   {:noreply, {id, messages, clients}}   
  # end

  def handle_cast({:on_the_feed, server_pid, tweet_by,message, chance},{id, messages, clients})do
    #IO.puts "user#{id} received a tweet from user#{source}:: #{msg}"
    chance =  if chance != 1 do
                100
              else
                1
              end
    if (:rand.uniform(chance) == 1) do
      retweet =   if (Regex.match?(~r/Retweeted/ , message)) do
                      message
                  else
                      message <> " - Retweeted source #{tweet_by}."
                  end
      #IO.puts "Retweeting: "<>rt_msg
      tweetId = GenServer.call(server_pid,{:tweet,id,message})
    end
    {:noreply,{id, messages, clients}}
  end


end
