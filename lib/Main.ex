defmodule Main do



    def main(args) do
      numClients = elem(Integer.parse(Enum.at(args, 0)), 0)
      numMessages = elem(Integer.parse(Enum.at(args, 1)), 0)
      :global.register_name(:main, self())
      :ets.new(:registration_counter, [:set, :public, :named_table])
      :ets.insert(:registration_counter, {"count",0})
      nodeid_list = Enum.map(1..numClients, fn(x) -> "client_"<>Integer.to_string(x) end)
      ApplicationSupervisor.start_link([numClients, numMessages])
      :ets.new(:time_printing, [:set, :public, :named_table])
      :ets.insert(:time_printing, {'tic', System.system_time(:millisecond)})
      simulator(numClients, numMessages,nodeid_list)
      
      #IO.puts "Total time taken => #{(toc-tic)/1000} seconds"

    end

    def simulator(numClients, numMessages,nodeid_list) do
      receive do
        {:clients_created} ->
          #register user
          Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:register}) end)
          subscribe(nodeid_list,numClients)
        {:registered} ->
          count = :ets.update_counter(:registration_counter, "count", {2,1})
          if count==numClients do
            #start simulation
            tweet_pool = Enum.map(nodeid_list, fn(x) -> x<>" is #great"  end)
            #IO.inspect tweet_pool
            Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:simulate,tweet_pool}) end)
          end
      end
        simulator(numClients, numMessages,nodeid_list)
    end

    #topmost nodes will be the most subscribed nodes
    def subscribe(nodeid_list, clients) do
    	#IO.inspect ["Clients: ", clients]
    	Enum.map(nodeid_list, fn(id) ->

		subscribe_to = 	cond do
		    				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.01) ->
		    					Enum.map(1..round(clients*0.01), fn n -> n end) -- [id]

		    				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.1) ->
		    					#IO.inspect "here"
		    					Enum.map(1..round(clients*0.1), fn n -> n end) -- [id]

		    				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.6) ->
		    					Enum.map(1..round(clients*0.6), fn n -> n end) -- [id]

		    				true ->
		    					#IO.inspect id
		    					Enum.take_random(1..clients, round(clients*0.8)) -- [id]
		    			end
		#IO.inspect [id, subscribe_to]
		GenServer.cast(String.to_atom(id),{:subscribe, subscribe_to})

    	end)
    	#:sys.get_state(Enum.at(clients,1))
	    #:sys.get_state(Enum.at(clients,0))
	    #:sys.get_state(:twitterServer)
    end
end
