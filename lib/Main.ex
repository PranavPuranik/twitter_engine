defmodule Main do
    def main(args) do
      numClients = elem(Integer.parse(Enum.at(args, 0)), 0)
      numMessages = elem(Integer.parse(Enum.at(args, 1)), 0)
      :global.register_name(:main, self())
      #ApplicationSupervisor.start_link([numClients, numMessages])
      #simulator(numClients, numMessages)
    end


    # def simulator(numClients, numMessages) do
    #   receive do
    #     {:clients_created} ->
    #       #register user
    #       nodes_list = Enum.to_list 1..numClients
    #       nodeid_list = Enum.map(nodes_list, fn(x) -> "worker_client_"<>Integer.to_string(x) end)
    #       Enum.map(nodeid_list, fn(x) -> GenServer.call(String.to_atom(x),{:register}) end)
    #     {:simulation} ->
    #   end
    #     simulator(clients, messages)
    # end
end
