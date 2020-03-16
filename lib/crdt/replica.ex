defmodule CRDT.Replica do
  # A wrapper for the different CRDT implementations

  use Agent

  def start_link(params) do
    initial_value =
      case params do
        {:pn_counter, size, i} ->
          initial_value(:pn_counter, CRDT.PNCounterServer.start_link(size, i))

        {:g_counter, size, i} ->
          initial_value(:g_counter, nil)

        {:g_set, i} ->
          initial_value(:g_counter, nil)

        _ ->
          {:error, "The replica type doesn't exist."}
      end

    case initial_value do
      {:ok, pid, type} -> Agent.start_link(fn -> {type, pid} end, name: __MODULE__)
      {:error, message} -> {:error, message}
    end
  end

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

  def update(replica, params) do
  end

  def merge(replica, replica2) do
  end

  def compare(replica, replica2) do
  end

  defp initial_value(type, server) do
    case server do
      {:ok, pid} -> {:ok, pid, type}
      {:error, _} -> {:error, "Could not start replica."}
      _ -> {:error, "Invalid server."}
    end
  end
end
