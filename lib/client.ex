defmodule TwitterEngine.Client do
  use GenServer


  # Initialization
  def start_link({id, messages, clients}) do
    GenServer.start_link(__MODULE__, {id, messages, clients}, name: String.to_atom("client_#{id}"))
  end

  def init({id, messages, clients}) do
    {:ok, {id, messages, clients}}
  end

  def handle_call({:register,server_pid}, _from,{id, messages, clients}) do
    GenServer.call(server_pid,{:registerUser,id})
    {:reply,[], {id, messages, clients}}
  end

  def handle_call({:deRegister,server_pid}, _from,{id, messages, clients}) do
    GenServer.call(server_pid,{:deRegisterUser,id})
    {:reply,[], {id, messages, clients}}
  end

  def handle_call({:tweet,server_pid,tweet_pool}, _from,{id, messages, clients}) do
    msg = Enum.random(tweet_pool)
    tweetId = GenServer.call(server_pid,{:tweet,id,msg})
    {:reply,tweetId, {id, messages, clients}}
  end

end
