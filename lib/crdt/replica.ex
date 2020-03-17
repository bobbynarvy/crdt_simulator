defmodule CRDT.Replica do
  # A wrapper for the different CRDT implementations

  use Agent

  @spec start_link(tuple) :: {:ok, pid} | {:error, String.t()}
  def start_link(params) do
    initial_value =
      case params do
        {:pn_counter, size, i} ->
          initial_value(:pn_counter, CRDT.PNCounterServer.start_link({size, i}))

        {:g_counter, size, i} ->
          initial_value(:g_counter, nil)

        {:g_set, i} ->
          initial_value(:g_counter, nil)

        _ ->
          {:error, "The replica type doesn't exist."}
      end

    case initial_value do
      {:ok, pid, type} -> Agent.start_link(fn -> {type, pid} end)
      {:error, message} -> {:error, message}
    end
  end

  @spec query(pid, atom) :: term | {:error, String.t()}
  def query(replica, params) do
    Agent.get(replica, fn {type, pid} ->
      case type do
        :pn_counter ->
          CRDT.PNCounterServer.query(pid, params)

        _ ->
          {:error, "Invalid replica."}
      end
    end)
  end

  @spec update(pid, tuple) :: :ok | {:error, String.t()}
  def update(replica, params) do
    Agent.get(replica, fn {type, pid} ->
      case type do
        :pn_counter ->
          CRDT.PNCounterServer.update(pid, params)

        _ ->
          {:error, "Invalid replica."}
      end
    end)
  end

  @spec merge(pid, pid) :: :ok | {:error, String.t()}
  def merge(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {type1, _, type2, _} when type1 != type2 ->
        {:error, "The replicas do not have the same type."}

      {type, pid1, _, pid2} ->
        case type do
          :pn_counter ->
            CRDT.PNCounterServer.merge(pid1, pid2)

          _ ->
            {:error, "Invalid replica."}
        end
    end
  end

  @spec compare(pid, pid) :: boolean | {:error, String.t()}
  def compare(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {type1, _, type2, _} when type1 != type2 ->
        {:error, "The replicas do not have the same type."}

      {type, pid1, _, pid2} ->
        case type do
          :pn_counter ->
            CRDT.PNCounterServer.compare(pid1, pid2)

          _ ->
            {:error, "Invalid replica."}
        end
    end
  end

  defp initial_value(type, server) do
    case server do
      {:ok, pid} -> {:ok, pid, type}
      {:error, _} -> {:error, "Could not start replica."}
      _ -> {:error, "Invalid server."}
    end
  end

  defp with_two_replicas(replica1, replica2) do
    Agent.get(replica1, fn {type1, pid1} ->
      Agent.get(replica2, fn {type2, pid2} ->
        {type1, pid1, type2, pid2}
      end)
    end)
  end
end
