defmodule CRDT.Poller do
  use Agent

  @moduledoc """
  Polls the replicas in the registry
  and prompts on updates
  """

  @doc """
  Start the poller with an optional polling interval
  """
  def start_link(poll_interval \\ 1000) do
    IO.puts("Starting to poll replicas...")

    initial_state = %{
      interval: poll_interval,
      replica_values: []
    }

    {:ok, pid} = Agent.start_link(fn -> initial_state end, name: __MODULE__)

    spawn_link(fn -> poll_process() end)

    {:ok, pid}
  end

  defp poll_process() do
    current_values =
      for replica <- CRDT.Registry.replicas() do
        value = CRDT.Replica.query(replica, :value)

        case replica do
          replica when is_map(replica) -> MapSet.to_list(value)
          _ -> value
        end
      end

    replica_values = Agent.get(__MODULE__, fn state -> state.replica_values end)

    if current_values != replica_values do
      IO.inspect(current_values, label: "Replicas updated")
      Agent.update(__MODULE__, fn state -> %{state | replica_values: current_values} end)
    end

    Process.sleep(Agent.get(__MODULE__, fn state -> state.interval end))

    poll_process()
  end
end
