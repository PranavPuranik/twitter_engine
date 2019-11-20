defmodule TwitterEngine.Client do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer

  # Initialization
  def start_link({id, messages, clients}) do
    #IO.puts "Here #{id}"
    GenServer.start_link(__MODULE__, {id, messages, clients}, name: String.to_atom("client_#{id}"))
  end

  def init({id, messages, clients}) do

    IO.puts "Client #{id} Started"
    IO.puts "-------------------------------"
    
    {:ok, {id, messages, clients}}
  end

  # API
  def register_self() do
    GenServer.cast(self(), {:register})
  end

  def bar(value) do
    #GenServer.cast(__MODULE__, {:bar, [value]})
  end

  # Callbacks
  # def handle_call({:register, [value]}, _from, state) do
  #   resp = "value: #{inspect value}"
  #   state = %{state|foo: value}
  #   {:reply, resp, state}
  # end


  def handle_call({:register}, _from, {id, messages, clients}) do
    
    _ = GenServer.call({:twitterServer,'abc'},{:registeruser,id})

    {:reply, [], {id, messages, clients}}
  end


  def handle_cast({:register}, {id, messages, clients}) do
    my_tweets = ["Tweet from #{id}"]
    #ZIPF: Randomly start tweeting/retweeting/subscribe/querying activities acc to zipf rank
    messages = cond do
       id <= (clients * 0.01) ->
          messages * 20
           
       id <= (clients*0.1) ->
          messages * 10
       
       id <= (clients*0.6) ->
          messages * 2

       true ->
          messages
     end
    GenServer.cast({:twitterServer,'abc'},{:registeruser,id})
    
    {:noreply, {id, messages, clients}}
  end

  # def handle_info({:baz, [value]}, state) do
  #   state = %{state|baz: value}
  #   {:noreply, state}
  # end

  # Helpers

  defp transform_bar(value) do
    "transformed: #{inspect value}"
  end

end