defmodule TwitterEngine do
  use Application

  @impl true
  def start(_type, args) do
  	Main.main(args)
  end
end

args = System.argv()
TwitterEngine.start([], args)