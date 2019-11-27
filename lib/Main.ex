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

    	#considering s = 1
    	c = 1 / Enum.sum(Enum.map(1..clients, fn n -> 1/n end))

    	all_clients = Enum.map(1..clients, fn n -> n end)

    	Enum.map(nodeid_list, fn(id) ->
    		#IO.inspect all_clients --[elem(Integer.parse(String.slice(id, 7..-1)),0)]
			subscribers = 	Enum.take_random(
								all_clients --[elem(Integer.parse(String.slice(id, 7..-1)),0)], round(c * clients/ elem(Integer.parse(String.slice(id, 7..-1)),0))
							)
							
							# cond do
			    # 				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.01) ->
			    # 					Enum.map(Enum.take_random(all_clients -- [id]), fn n -> 
			    # 						n 
			    # 					end)

			    # 				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.1) ->
			    # 					#IO.inspect "here"
			    # 					Enum.map(1..round(clients*0.1), fn n -> n end) -- [id]

			    # 				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.6) ->
			    # 					Enum.map(1..round(clients*0.6), fn n -> n end) -- [id]

			    # 				elem(Integer.parse(String.slice(id, 7..-1)),0) <= (clients*0.9) ->
			    # 					Enum.map(1..round(clients*0.9), fn n -> n end) -- [id]

			    # 				true ->
			    # 					#IO.inspect id
			    # 					random_to_subscribe = Enum.random(1..clients)
			    # 					Enum.map(1..random_to_subscribe,fn n -> n end) -- [id]
			    # 			end
			#IO.inspect [id, List.flatten(subscribers)], charlists: :as_lists

			Enum.each(subscribers, fn n-> 
				GenServer.cast(String.to_atom("client_"<>Integer.to_string(n)),
					{:subscribe, [elem(Integer.parse(String.slice(id, 7..-1)),0)]})
    		end)

			GenServer.cast(String.to_atom(id), {:set_Messaages, subscribers})

    	end)



    end
end
