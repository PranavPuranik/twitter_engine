defmodule Main do
    def main(args) do
      clients = elem(Integer.parse(Enum.at(args, 0)), 0)
      messages = elem(Integer.parse(Enum.at(args, 1)), 0)
      :global.register_name(:main, self())
      ApplicationSupervisor.start_link([clients, messages])
    end
end
