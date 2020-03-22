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
  def query(server, type) do
    GenServer.call(server, {:query, type})
  end

  @impl Server
  def update(server, {:increment}) do
    GenServer.call(server, {:update, :increment})
  end

  @impl Server
  def compare(server, server2) do
    GenServer.call(server, {:compare, server2})
  end

  @impl Server
  def merge(server, server2) do
    GenServer.call(server, {:merge, server2})
  end

  def handle_call({:query, type}, _from, state) do
    case type do
      :payload -> {:reply, state.payload, state}
      :value -> {:reply, GC.query({:value, state.payload}), state}
    end
  end

  def handle_call({:update, :increment}, _from, state) do
    new_state = %{state | payload: GC.update({:increment, state.payload, state.position})}
    {:reply, :ok, new_state}
  end

  def handle_call({:compare, server2}, _from, state) do
    server2_payload = query(server2, :payload)
    {:reply, GC.compare(state.payload, server2_payload), state}
  end

  def handle_call({:merge, server2}, _from, state) do
    server2_payload = query(server2, :payload)
    new_state = %{state | payload: GC.merge(state.payload, server2_payload)}
    {:reply, :ok, new_state}
  end
end
