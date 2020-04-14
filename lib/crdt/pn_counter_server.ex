defmodule CRDT.PNCounterServer do
  use GenServer
  alias CRDT.PNCounter, as: PNC
  alias CRDT.Server, as: Server
  @behaviour Server

  @moduledoc """
  Implements a stateful Positive-Negative Counter CRDT
  """

  # Client

  @doc """
  Starts a counter server process
  """
  @impl Server
  def start_link({n, position}) do
    state = %{
      counter: PNC.initialize(n),
      position: position
    }

    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Queries the state of the counter
  """
  @impl Server
  def query(server, type) do
    GenServer.call(server, {:query, type})
  end

  @doc """
  Updates the value of the counter
  """
  @impl Server
  def update(server, {type}) do
    GenServer.call(server, {:update, type})
  end

  @doc """
  Compares the values of two counters
  """
  @impl Server
  def compare(server1, server2) do
    GenServer.call(server1, {:compare, server2})
  end

  @doc """
  Merges the values of two counters
  """
  @impl Server
  def merge(server1, server2) do
    GenServer.call(server1, {:merge, server2})
  end

  # Server

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:query, type}, _from, state) do
    case type do
      :payload -> {:reply, state.counter, state}
      :value -> {:reply, PNC.query({:value, state.counter}), state}
    end
  end

  @impl true
  def handle_call({:update, type}, _from, state) do
    new_state =
      Map.update!(state, :counter, fn counter ->
        PNC.update({type, counter, state.position})
      end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:compare, server2}, _from, state) do
    server2_counter = query(server2, :payload)
    comparison = PNC.compare(state.counter, server2_counter)

    {:reply, comparison, state}
  end

  @impl true
  def handle_call({:merge, server2}, _from, state) do
    server2_counter = query(server2, :payload)

    new_state =
      Map.update!(state, :counter, fn counter ->
        PNC.merge(counter, server2_counter)
      end)

    {:reply, :ok, new_state}
  end
end
