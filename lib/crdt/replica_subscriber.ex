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

      @doc """
      Subscribes the implementing process to a replica
      """
      def subscribe(replica) do
        spawn(fn ->
          Replica.subscribe(replica, self())

          handle_events(replica, %{events: []})
        end)
      end

      @doc """
      Returns a list of events that have been
      sent to the subscriber
      """
      def events(subscriber) do
        send(subscriber, {:events, self()})

        receive do
          {:events, events} -> events
          _ -> {:error, "Events not retrieved."}
        end
      end

      @doc false
      def handle_replica_call(_, _), do: raise("function not implemented")

      defp handle_events(replica, state) do
        now = DateTime.now("Etc/UTC")

        new_state =
          receive do
            :update ->
              handle_replica_call(replica, :updated)
              %{state | events: [{:update, now} | state.events]}

            {:events, pid} ->
              send(pid, {:events, state.events})
              state

            _ ->
              %{
                state
                | events: [
                    {:error, "unhandled replica event", now} | state.events
                  ]
              }
          end

        handle_events(replica, new_state)
      end

      defoverridable handle_replica_call: 2
    end
  end
end
