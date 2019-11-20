defmodule TwitterEngine.Client do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer

  # Initialization
  def start_link({x, messages}) do
    GenServer.start_link(__MODULE__, opts, [name: String.to_atom("client-#{x}")])
  end

  def init(opts) do
    
    {:ok, opts}
  end

  # API
  def foo(value) do
    #GenServer.call(__MODULE__, {:foo, [value]})
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



  def handle_cast({:register}, {id, messages}) do
    my_tweets = ["Tweet from #{id}"]
    #ZIPF: Randomly start tweeting/retweeting/subscribe/querying activities acc to zipf rank
    acts = cond do
       id <= (clients*0.01) ->
          messages * 20
           
       id <= (clients*0.1) ->
          messages * 10
       
       id <= (clients*0.6) ->
          messages * 2

       true ->
          messages
     end
    GenServer.cast({:twitterServer,servernode},{:registeruser,id})
    
    {:noreply, {x, messages}}
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