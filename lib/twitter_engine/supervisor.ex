defmodule ApplicationSupervisor do
    use Supervisor

    def start_link(args) do
        Supervisor.start_link(__MODULE__,args)
    end

    def init([clients, messages]) do
      children = [
        worker(TwitterEngine.Server, ['sbc'], restart: :temporary) | 
        Enum.map(1..clients, fn n -> 
          worker(TwitterEngine.Client, [n, messages, clients], restart: :temporary) 
        end)
      ]
      IO.inspect children
      IO.puts "------------------------"
      Supervisor.start_link(children, strategy: :one_for_one)

    end

end
