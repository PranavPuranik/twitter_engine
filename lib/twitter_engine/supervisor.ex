defmodule ApplicationSupervisor do
    use Supervisor

    def start_link(args) do
        Supervisor.start_link(__MODULE__,args)
         GenServer.cast(:main,{:clients_created})
    end

    def init([clients, messages]) do
      children = [
        worker(TwitterEngine.Server, ["twitterServer"], [id: "server"]) |
        Enum.map(1..clients, fn n ->
          worker(TwitterEngine.Client, [{n, messages, clients}], [id: "worker_client_#{n}"] )
        end)
      ]

      supervise children, strategy: :one_for_one
    end

end
