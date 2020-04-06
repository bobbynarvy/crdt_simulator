defmodule CRDT.ReplicaBroadcaster do
  use CRDT.ReplicaSubscriber
  use Agent

  alias CRDT.Registry
  alias CRDT.Replica

  def start_link(registry_pid) do
    {:ok, broadcaster} = Broadcaster.start_link()

    subscriptions =
      for replica <- Registry.replicas() do
        subscribe(replica)
        Broadcaster.add_recipient(broadcaster, replica)
        replica
      end

    initial_state = %{
      broadcaster: broadcaster,
      messages: [],
      subscriptions: subscriptions,
      # delays the next update to a given replica
      delay: %{
        replica: nil,
        duration: 0
      }
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

  def delay(index, duration), do: set_delay(index, duration)

  def handle_replica_call(replica, type) do
    neighbors = Enum.filter(state().subscriptions, fn pid -> pid != replica end)

    case type do
      :updated ->
        add_update_message(replica, neighbors)

        for neighbor <- neighbors do
          Broadcaster.send_msg(
            state().broadcaster,
            {fn receiver ->
               Replica.merge(replica, receiver)
               Replica.merge(receiver, replica)
             end, neighbor, broadcaster_opts(neighbor)}
          )
        end

      _ ->
        {:error, "Undefined replica update"}
    end
  end

  defp state() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  defp broadcaster_opts(replica) do
    %{}
    |> (fn opts ->
          if state().delay.replica == replica do
            %{delay: state().delay.duration}
          else
            opts
          end
        end).()
  end

  defp add_update_message(sender_pid, neighbor_pids) do
    update_message = %{sender: sender_pid, recipients: neighbor_pids}

    Agent.update(__MODULE__, fn state ->
      %{state | messages: state.messages ++ [update_message]}
    end)
  end

  defp set_delay(index, duration) do
    Agent.update(__MODULE__, fn state ->
      Map.merge(state, %{
        delay: %{
          replica: Enum.at(state.subscriptions, index),
          duration: duration
        }
      })
    end)
  end
end
