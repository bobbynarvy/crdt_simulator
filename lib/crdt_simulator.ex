defmodule CRDTSimulator do
  use Application

  def start(_type, _args) do
    IO.puts("Starting CRDTSimulator...")
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
