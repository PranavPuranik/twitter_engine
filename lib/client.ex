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

  def handle_call({:tweet,server_pid,tweet_pool}, _from,{id, messages, clients}) do
    msg = Enum.random(tweet_pool)
    tweetId = GenServer.call(server_pid,{:tweet,id,msg})
    {:reply,tweetId, {id, messages, clients}}
  end

  def handle_call({:queryHashTags,server_pid,hashTag},_from,{id, messages, clients}) do
    tweets = GenServer.call(server_pid,{:queryHashTags,hashTag})
    {:reply,tweets, {id, messages, clients}}
  end

  def handle_call({:queryMyMention,server_pid,mention},_from,{id, messages, clients}) do
    tweets = GenServer.call(server_pid,{:queryMyMention,mention})
    {:reply,tweets, {id, messages, clients}}
  end

  def handle_cast({:subscribe, server_pid, subscribe_to},{id, messages, clients})do
    GenServer.cast(server_pid,{:subscribe,id,subscribe_to})
    {:noreply, {id, messages, clients}}
  end

  def handle_call({:allSubscribedTweets,server_pid},{id, messages, clients})do
    GenServer.call(server_pid,{:allSubscribedTweets,id})
    {:noreply, {id, messages, clients}}
  end


end
