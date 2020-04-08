defmodule CRDTSimulator.MixProject do
  use Mix.Project

  def project do
    [
      app: :crdt_simulator,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {CRDTSimulator, []},
      extra_applications: [:logger]
    ]
  end
end
