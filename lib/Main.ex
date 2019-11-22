defmodule Main do

    def main(args) do
      numClients = elem(Integer.parse(Enum.at(args, 0)), 0)
      numMessages = elem(Integer.parse(Enum.at(args, 1)), 0)
      :global.register_name(:main, self())
      ApplicationSupervisor.start_link([numClients, numMessages])
      :ets.new(:registration_counter, [:set, :public, :named_table])
      :ets.insert(:registration_counter, {"count",0})
      simulator(numClients, numMessages)
    end


    def simulator(numClients, numMessages) do
      receive do
        {:clients_created} ->
          #register user
          nodeid_list = Enum.map(1..numClients, fn(x) -> "worker_client_"<>Integer.to_string(x) end)
          Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:register}) end)
          subscribe(nodeid_list,numClients)
        {:registered} ->
          count = :ets.update_counter(:registration_counter, "count", {2,1})
          if count==numClients do
            #start simulation
            nodeid_list = Enum.map(1..numClients, fn(x) -> "worker_client_"<>Integer.to_string(x) end)
            tweet_pool = Enum.map(nodeid_list, fn(x) -> Integer.to_string(x)<>" is #"<>"great"  end)
            Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:simulate,1,numMessages,tweet_pool}) end)
          end
      end
        simulator(numClients, numMessages)
    end

    #topmost nodes will be the most subscribed nodes
    def subscribe(nodeid_list, clients) do
    	Enum.map(nodeid_list, fn(id) -> 
    			subscribe_to = 	cond do
				    				id <= (clients*0.01) ->
				    					[1..(clients*0.01)] -- [id]

				    				id <= (clients*0.1) ->
				    					[1..(clients*0.1)] -- [id]

				    				id <= (clients*0.5) ->
				    					[1..(clients*0.6)] -- [id]

				    				true -> 
				    					Enum.take_random([1..clients, round(clients*0.8)])
				    			end 
    			GenServer.cast(String.to_atom("client_#{id}"),{:subscribe, subscribe_to}	) 
    	end)
    end
end
