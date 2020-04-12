defmodule CRDT.Poller do
  use Agent

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
        CRDT.Replica.query(replica, :value)
      end

    replica_values = Agent.get(__MODULE__, fn state -> state.replica_values end)

    if current_values != replica_values do
      values_string = Enum.map(current_values, &Integer.to_string/1) |> Enum.join(", ")
      IO.puts("Replicas updated: #{values_string}")
      Agent.update(__MODULE__, fn state -> %{state | replica_values: current_values} end)
    end

    Process.sleep(Agent.get(__MODULE__, fn state -> state.interval end))

    poll_process()
  end
end
