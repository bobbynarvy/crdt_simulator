defmodule CRDT.ReplicaBroadcasterTest do
  use ExUnit.Case
  alias CRDT.Registry, as: R
  alias CRDT.ReplicaBroadcaster, as: RB

  setup do
    {:ok, registry_pid} = R.start_link(:pn_counter, 3)
    {:ok, _} = RB.start_link(registry_pid)
    {:ok}
  end

  test "subscribes to a replica" do
    status = RB.subscribe(R.replicas(0))
    assert status == :ok
  end

  test "queries the value of all replicas" do
    value = RB.query(:value)
    assert value == [0, 0, 0]
  end

  test "queries the value of a replica" do
    value = RB.query(:value, 0)
    assert value == 0
  end

  describe "when updating a replica" do
    setup do
      RB.start_link(:pn_counter, 3)

      replica = RB.replicas(0)
      CRDT.Replica.update(replica, {:increment})
      {:ok}
    end

    test "sends a merge message to replicas" do
      # When a replica is updated, the broadcaster
      # should broadcast the change to the other replicas

      # Because broadcasts are asynchronous, sleep
      # for a second to make sure that all messages 
      # have been broadcasted and processed
      Process.sleep(1000)

      assert RB.query(:value) == [1, 1, 1]
    end

    test "sends a message only to the non-origin replicas" do
      %{recipients: recipients} = List.last(RB.messages())

      assert Enum.member?(recipients, RB.replicas(0)) == false
      assert Enum.member?(recipients, RB.replicas(1)) == true
      assert Enum.member?(recipients, RB.replicas(2)) == true
    end
  end

  # TO DO: Tests on deliberate failues and delays
end
