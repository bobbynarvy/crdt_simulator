defmodule CRDT.Replica do
  alias CRDT.PNCounterServer, as: PCS
  alias CRDT.GCounterServer, as: GCS
  alias CRDT.GSetServer, as: GS
  alias CRDT.TPSetServer, as: TPS

  use Agent

  @moduledoc """
  A wrapper for the different CRDT implementations
  """

  @doc """
  Start a replica process that stores a 
  reference to a CRDT server
  """
  @spec start_link(tuple) :: {:ok, pid} | {:error, String.t()}
  def start_link(params) do
    initial_value =
      case params do
        {:pn_counter, size, i} ->
          initial_value(:pn_counter, PCS.start_link({size, i}))

        {:g_counter, size, i} ->
          initial_value(:g_counter, GCS.start_link({size, i}))

        {:g_set} ->
          initial_value(:g_set, GS.start_link({}))

        {:tp_set} ->
          initial_value(:tp_set, TPS.start_link({}))

        _ ->
          {:error, "The replica type doesn't exist."}
      end

    case initial_value do
      {:ok, pid, type} -> Agent.start_link(fn -> {type, pid, []} end)
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Query the CRDT server references by a
  replica process
  """
  @spec query(pid, atom | tuple) :: term | {:error, String.t()}
  def query(replica, params) do
    Agent.get(replica, fn {type, pid, _} ->
      apply_to_valid_module(type, fn module -> module.query(pid, params) end)
    end)
  end

  @doc """
  Update the state of a replica
  """
  @spec update(pid, tuple) :: :ok | {:error, String.t()}
  def update(replica, params) do
    result =
      Agent.get(replica, fn {type, pid, _} ->
        apply_to_valid_module(type, fn module -> module.update(pid, params) end)
      end)

    Agent.get(replica, fn {_, _, subscribers} ->
      for subscriber <- subscribers, do: send(subscriber, :update)
    end)

    result
  end

  @doc """
  Merge the value of the replica
  with that of another
  """
  @spec merge(pid, pid) :: :ok | {:error, String.t()}
  def merge(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {:error, error} ->
        {:error, error}

      {type, pid1, pid2} ->
        apply_to_valid_module(type, fn module -> module.merge(pid1, pid2) end)
    end
  end

  @doc """
  Compare the value of the replica
  with that of another
  """
  @spec compare(pid, pid) :: boolean | {:error, String.t()}
  def compare(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {:error, error} ->
        {:error, error}

      {type, pid1, pid2} ->
        apply_to_valid_module(type, fn module -> module.compare(pid1, pid2) end)
    end
  end

  @doc """
  Adds a subscriber to replica updates.
  Subscribers must use and implement CRDT.ReplicaSubscriber
  """
  @spec subscribe(pid, pid) :: :ok
  def subscribe(replica, subscriber) do
    Agent.update(replica, fn {type, pid, subscribers} ->
      {type, pid, [subscriber | subscribers]}
    end)
  end

  defp initial_value(type, server) do
    case server do
      {:ok, pid} -> {:ok, pid, type}
      {:error, _} -> {:error, "Could not start replica."}
      _ -> {:error, "Invalid server."}
    end
  end

  defp crdt_module(atom) do
    case atom do
      :pn_counter -> PCS
      :g_counter -> GCS
      :g_set -> GS
      :tp_set -> TPS
      _ -> nil
    end
  end

  defp apply_to_valid_module(atom, apply_fn) do
    valid_atoms = [:pn_counter, :g_counter, :g_set, :tp_set]

    if Enum.member?(valid_atoms, atom) do
      apply_fn.(crdt_module(atom))
    else
      {:error, "Invalid replica"}
    end
  end

  defp with_two_replicas(replica1, replica2) do
    Agent.get(replica1, fn {type1, pid1, _} ->
      Agent.get(replica2, fn {type2, pid2, _} ->
        if type1 != type2 do
          {:error, "The replicas do not have the same type."}
        else
          {type1, pid1, pid2}
        end
      end)
    end)
  end
end
