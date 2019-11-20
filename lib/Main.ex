defmodule Main do
    def main(args) do
      :global.register_name(:main, self())
      ApplicationSupervisor.start_link([String.to_atom("nonames@"<>"noonodess")])
    end
end
