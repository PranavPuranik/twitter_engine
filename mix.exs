defmodule Twitterengine.MixProject do
  use Mix.Project

  def project do
    [
      app: :twitterengine,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def escript() do
    [main_module: Main]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:veritaserum, "~> 0.2.0"}
    ]
  end
end
