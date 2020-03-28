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
    Subscriber.subscribe(ctx.replica, self())
    Replica.update(ctx.replica, {:increment})

    result =
      receive do
        :ok -> :ok
      end

    assert result == :ok
  end
end
