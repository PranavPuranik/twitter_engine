defmodule ApplicationSupervisor do
    use Supervisor

    def start_link(args) do
        {:ok,pid} = Supervisor.start_link(__MODULE__,args)
        send(:global.whereis_name(:main),{:clients_created})
        {:ok,pid}
    end

    def init([clients, messages]) do
      children = [
        worker(TwitterEngine.Server, [{"twitterServer", clients}], [id: "server"]) |
        Enum.map(1..clients, fn n ->
          worker(TwitterEngine.Client, [{n, messages, clients}], [id: "worker_client_#{n}"] )
        end)
      ]

      supervise children, strategy: :one_for_one
    end

end
