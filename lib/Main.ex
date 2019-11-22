defmodule Main do

    def main(args) do
      numClients = elem(Integer.parse(Enum.at(args, 0)), 0)
      numMessages = elem(Integer.parse(Enum.at(args, 1)), 0)
      :global.register_name(:main, self())
      :ets.new(:registration_counter, [:set, :public, :named_table])
      :ets.insert(:registration_counter, {"count",0})
      nodeid_list = Enum.map(1..numClients, fn(x) -> "client_"<>Integer.to_string(x) end)
      ApplicationSupervisor.start_link([numClients, numMessages])
      simulator(numClients, numMessages,nodeid_list)
    end

    def simulator(numClients, numMessages,nodeid_list) do
      receive do
        {:clients_created} ->
          #register user
          Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:register}) end)
        {:registered} ->
          count = :ets.update_counter(:registration_counter, "count", {2,1})
          if count==numClients do
            #start simulation
            tweet_pool = Enum.map(nodeid_list, fn(x) -> x<>" is #great"  end)
            Enum.map(nodeid_list, fn(x) -> GenServer.cast(String.to_atom(x),{:simulate,1,numMessages,tweet_pool}) end)
          end
      end
        simulator(numClients, numMessages,nodeid_list)
    end
end
