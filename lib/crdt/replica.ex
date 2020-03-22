defmodule CRDT.Replica do
  # A wrapper for the different CRDT implementations

  alias CRDT.PNCounterServer, as: PCS
  alias CRDT.GCounterServer, as: GCS
  use Agent

  @spec start_link(tuple) :: {:ok, pid} | {:error, String.t()}
  def start_link(params) do
    initial_value =
      case params do
        {:pn_counter, size, i} ->
          initial_value(:pn_counter, PCS.start_link({size, i}))

        {:g_counter, size, i} ->
          initial_value(:g_counter, GCS.start_link({size, i}))

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
          PCS.query(pid, params)

        :g_counter ->
          GCS.query(pid, params)

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
          PCS.update(pid, params)

        :g_counter ->
          GCS.update(pid, params)

        _ ->
          {:error, "Invalid replica."}
      end
    end)
  end

  @spec merge(pid, pid) :: :ok | {:error, String.t()}
  def merge(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {:error, error} ->
        {:error, error}

      {type, pid1, pid2} ->
        case type do
          :pn_counter ->
            PCS.merge(pid1, pid2)

          :g_counter ->
            GCS.merge(pid1, pid2)

          _ ->
            {:error, "Invalid replica."}
        end
    end
  end

  @spec compare(pid, pid) :: boolean | {:error, String.t()}
  def compare(replica, replica2) do
    case with_two_replicas(replica, replica2) do
      {:error, error} ->
        {:error, error}

      {type, pid1, pid2} ->
        case type do
          :pn_counter ->
            PCS.compare(pid1, pid2)

          :g_counter ->
            GCS.compare(pid1, pid2)

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
        if type1 != type2 do
          {:error, "The replicas do not have the same type."}
        else
          {type1, pid1, pid2}
        end
      end)
    end)
  end
end
