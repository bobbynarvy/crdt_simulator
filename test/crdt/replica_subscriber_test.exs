defmodule CRDT.ReplicaSubscriberTest do
  use ExUnit.Case
  alias CRDT.Replica

  defmodule Subscriber do
    use CRDT.ReplicaSubscriber

    def handle_replica_call(_replica, type) do
      case type do
        :updated -> :ok
        _ -> {:error, "Undefined replica update"}
      end
    end
  end

  setup do
    {_, replica} = Replica.start_link({:pn_counter, 3, 1})
    {:ok, replica: replica}
  end

  test "subscriber receives and handles replica messages", ctx do
    pid = Subscriber.subscribe(ctx.replica)
    Replica.update(ctx.replica, {:increment})

    events = Subscriber.events(pid)
    [{event, _}] = events

    assert length(events) == 1
    assert event == :update
  end
end
