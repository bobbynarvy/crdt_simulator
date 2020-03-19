defmodule CRDT.GCounterServer do
  use GenServer
  alias CRDT.GCounter, as: GC
  alias CRDT.Server, as: Server
  @behaviour Server

  @impl Server
  def start_link({n, pos}) do
    init_state = %{
      position: pos,
      payload: GC.initialize(n)
    }

    GenServer.start_link(__MODULE__, init_state)
  end

  @impl Server
  def query(server, {type}) do
  end

  @impl Server
  def update(server, {params}) do
  end

  @impl Server
  def compare(server, server2) do
  end

  @impl Server
  def merge(server, server2) do
  end
end
