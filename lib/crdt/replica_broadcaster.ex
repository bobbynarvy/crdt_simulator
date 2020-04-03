defmodule CRDT.ReplicaBroadcaster do
  use CRDT.ReplicaSubscriber
  use Agent

  alias CRDT.Registry
  alias CRDT.Replica
  alias Broadcaster

  def start_link(registry_pid) do
    subscriptions =
      for replica <- Registry.replicas() do
        subscribe(replica)
        replica
      end

    initial_state = %{
      messages: [],
      subscriptions: subscriptions
    }

    {:ok, Agent.start_link(fn -> initial_state end, name: __MODULE__)}
  end

  def subscribed?(pid), do: Enum.member?(state().subscriptions, pid)

  def messages(), do: state().messages

  def query(type) do
    case type do
      :value -> for replica <- state().subscriptions, do: Replica.query(replica, :value)
      _ -> {:error, "Unknown query type"}
    end
  end

  def query(type, index) do
    case type do
      :value -> Replica.query(Enum.at(state().subscriptions, index), :value)
      _ -> {:error, "Unknown query type"}
    end
  end

  defp state() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def handle_replica_call(replica, type) do
    neighbors = Enum.filter(state().subscriptions, fn pid -> pid != replica end)

    case type do
      :updated ->
        for neighbor <- neighbors do
          Replica.merge(replica, neighbor)
          Replica.merge(neighbor, replica)
        end

      _ ->
        {:error, "Undefined replica update"}
    end
  end
end
