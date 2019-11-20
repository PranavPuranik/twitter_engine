defmodule ApplicationSupervisor do
    use Supervisor

    def start_link(args) do
        Supervisor.start_link(__MODULE__,args)
    end

    def init(args) do
      children = [
        worker(TwitterServer, [args], restart: :temporary)
      ]
      Supervisor.start_link(children, strategy: :one_for_one)
    end

end
