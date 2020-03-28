defmodule CRDT.ReplicaSubscriber do
  @moduledoc """
  This module is meant to be used by other modules
  that wish to subscribe to a replica. These modules
  must implement the handle_replica_call function
  """

  @callback handle_replica_call(pid, atom()) :: :ok | {:error, String.t()}

  alias CRDT.Replica

  defmacro __using__(_opts) do
    quote do
      @behaviour CRDT.ReplicaSubscriber

      def subscribe(replica, from) do
        spawn(fn ->
          Replica.subscribe(replica, self())

          wait_for_replica_msgs(replica, from)
        end)
      end

      @doc false
      def handle_replica_call(_, _), do: raise("function not implemented")

      defp wait_for_replica_msgs(replica, from) do
        receive do
          :update -> send(from, handle_replica_call(replica, :updated))
          _ -> send(from, {:error, "unhandled replica event"})
        end

        wait_for_replica_msgs(replica, from)
      end

      defoverridable handle_replica_call: 2
    end
  end
end
