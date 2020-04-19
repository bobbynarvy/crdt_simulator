defmodule CRDT.GSetServer do
  use GenServer
  alias CRDT.GSet, as: GS
  alias CRDT.Server, as: Server
  @behaviour Server

  @moduledoc """
  Implements a stateful Grow-Only Set CRDT
  """

  @doc """
  Starts a set server process
  """
  @impl Server
  def start_link({}) do
    GenServer.start_link(__MODULE__, GS.initialize())
  end

  @doc """
  Returns the current set
  """
  @impl Server
  def query(server, :payload) do
    GenServer.call(server, {:query, :payload})
  end

  @doc """
  Queries whether an element belongs to a set 
  """
  @impl Server
  def query(server, {:lookup, elem}) do
    GenServer.call(server, {:query, :lookup, elem})
  end

  @doc """
  Adds an element to the set 
  """
  @impl Server
  def update(server, {:add, elem}) do
    GenServer.call(server, {:update, :add, elem})
  end

  @doc """
  Compares the value of one set to another
  """
  @impl Server
  def compare(server, server2) do
    GenServer.call(server, {:compare, server2})
  end

  @doc """
  Merges the value of one set with set 
  """
  @impl Server
  def merge(server, server2) do
    GenServer.call(server, {:merge, server2})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:query, :lookup, elem}, _from, state) do
    {:reply, GS.query({:lookup, state, elem}), state}
  end

  @impl true
  def handle_call({:query, :payload}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, :add, elem}, _from, state) do
    {:reply, :ok, GS.update({:add, state, elem})}
  end

  @impl true
  def handle_call({:compare, server2}, _from, state) do
    server2_set = query(server2, :payload)
    {:reply, GS.compare(state, server2_set), state}
  end

  @impl true
  def handle_call({:merge, server2}, _from, state) do
    server2_set = query(server2, :payload)
    new_state = GS.merge(state, server2_set)
    {:reply, :ok, new_state}
  end
end
