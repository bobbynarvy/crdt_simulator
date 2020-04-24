defmodule CRDT.Registry do
  @moduledoc """
  Provides a simple way to keep track of replicas
  """

  use Agent
  alias CRDT.Replica, as: R

  @replica_types [:pn_counter, :g_counter, :g_set, :tp_set]

  @doc """
  Start the registry
  """
  def start_link({type, num_reps}) when num_reps > 2 do
    replicas =
      case type do
        :pn_counter -> create_replicas(num_reps, fn n -> {:pn_counter, num_reps, n} end)
        :g_counter -> create_replicas(num_reps, fn n -> {:g_counter, num_reps, n} end)
        :g_set -> create_replicas(num_reps, fn _ -> {:g_set} end)
        :tp_set -> create_replicas(num_reps, fn _ -> {:tp_set} end)
      end

    Agent.start_link(fn -> %{type: type, replicas: replicas} end, name: __MODULE__)
  end

  @doc """
  Returns an error when the CRDT type is not valid
  """
  def start_link({type, _}) when type not in @replica_types do
    {:error, "Invalid replica type"}
  end

  @doc """
  Returns an error when there are less than 3 replicas
  to be initialized
  """
  def start_link({_, _}), do: {:error, "There must be at least 3 replicas to create."}

  @doc """
  Get the replica pids
  """
  def replicas() do
    Agent.get(__MODULE__, fn state -> state.replicas end)
  end

  @doc """
  Get a replica pid
  """
  def replicas(n) do
    Agent.get(__MODULE__, fn state -> Enum.at(state.replicas, n) end)
  end

  @doc """
  Get the CRDT type of the replicas
  """
  def crdt_type(), do: Agent.get(__MODULE__, fn state -> state.type end)

  defp create_replicas(num_reps, tuple_fn) do
    for n <- 0..(num_reps - 1) do
      {:ok, replica} = R.start_link(tuple_fn.(n))
      replica
    end
  end
end
