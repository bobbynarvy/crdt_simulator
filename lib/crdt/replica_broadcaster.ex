defmodule CRDT.ReplicaBroadcaster do
  use CRDT.ReplicaSubscriber
  use Agent

  alias CRDT.Registry
  alias CRDT.Replica

  @moduledoc """
  Broadcasts operations between different replicas
  and subscribes to replica updates.
  """

  @empty_delay %{replica: nil, duration: 0}

  @doc """
  Starts the broadcaster
  """
  def start_link() do
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
      delay: @empty_delay,
      # fails the next update to a given replica
      fail: nil
    }

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @doc """
  Checks if the broadcaster if subscribed to a replica process
  """
  def subscribed?(pid), do: Enum.member?(state().subscriptions, pid)

  @doc """
  Returns the update messages that have been received by the broadcaster
  """
  def messages(), do: state().messages

  @doc """
  Queries all replicas
  """
  def query(type) do
    case type do
      :value -> for replica <- state().subscriptions, do: Replica.query(replica, :value)
      _ -> {:error, "Unknown query type"}
    end
  end

  @doc """
  Queries a replica
  """
  def query(type, index) do
    case type do
      :value -> Replica.query(Enum.at(state().subscriptions, index), :value)
      _ -> {:error, "Unknown query type"}
    end
  end

  @doc """
  Delays delivery of a message to a replica
  """
  def delay(index, duration) do
    Agent.update(__MODULE__, fn state ->
      Map.merge(state, %{
        delay: %{
          replica: Enum.at(state.subscriptions, index),
          duration: duration
        }
      })
    end)
  end

  @doc """
  Fails the delivery of a message to a replica
  """
  def fail(index),
    do:
      Agent.update(__MODULE__, fn state ->
        %{state | fail: Enum.at(state.subscriptions, index)}
      end)

  @doc """
  Implements the callback required in CRDT.CRDT.ReplicaSubscriber.
  Merges the value of the updated replica to that of other replicas.
  """
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

        Agent.update(__MODULE__, fn state ->
          Map.merge(state, %{delay: @empty_delay, fail: nil})
        end)

      _ ->
        {:error, "Undefined replica update"}
    end
  end

  defp state() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  defp broadcaster_opts(replica) do
    cond do
      state().fail == replica -> %{fail: true}
      state().delay.replica == replica -> %{delay: state().delay.duration}
      true -> %{}
    end
  end

  defp add_update_message(sender_pid, neighbor_pids) do
    update_message = %{sender: sender_pid, recipients: neighbor_pids}

    Agent.update(__MODULE__, fn state ->
      %{state | messages: state.messages ++ [update_message]}
    end)
  end
end
