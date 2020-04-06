defmodule CRDT.ReplicaBroadcasterTest do
  use ExUnit.Case
  alias CRDT.Registry, as: R
  alias CRDT.ReplicaBroadcaster, as: RB
  alias CRDT.Replica

  setup do
    {:ok, registry_pid} = R.start_link(:pn_counter, 3)
    RB.start_link(registry_pid)
    :ok
  end

  test "subscribes to a replica" do
    subscribed? = RB.subscribed?(R.replicas(0))
    assert subscribed? == true
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
      {:ok, registry_pid} = R.start_link(:pn_counter, 3)
      {:ok, _} = RB.start_link(registry_pid)

      replica = R.replicas(0)
      Replica.update(replica, {:increment})
      :ok
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
      Process.sleep(1000)
      %{recipients: recipients} = List.last(RB.messages())

      assert Enum.member?(recipients, R.replicas(0)) == false
      assert Enum.member?(recipients, R.replicas(1)) == true
      assert Enum.member?(recipients, R.replicas(2)) == true
    end
  end

  describe "when broadcasting with deliberate delays" do
    setup do
      {:ok, registry_pid} = R.start_link(:pn_counter, 3)
      {:ok, _} = RB.start_link(registry_pid)
      {:ok, replica: R.replicas(0)}
    end

    test "delays an update delivery to specific replica", ctx do
      status = RB.delay(1, 3000)
      assert status == :ok

      Replica.update(ctx.replica, {:increment})

      # Sleep for one second to make sure that non-delayed messages
      # have been propagated
      Process.sleep(1000)
      assert RB.query(:value) == [1, 0, 1]

      # Sleep for another 2 seconds to make sure that the delayed
      # message has arrived
      Process.sleep(2000)
      assert RB.query(:value) == [1, 1, 1]
    end

    test "delay is only applied once", ctx do
      RB.delay(1, 3000)
      Replica.update(ctx.replica, {:increment})

      Process.sleep(3000)
      assert RB.query(:value) == [1, 1, 1]

      # Without a delay, updates should be instantaneous
      Replica.update(ctx.replica, {:increment})

      Process.sleep(1000)
      assert RB.query(:value) == [2, 2, 2]
    end

    test "resolves to a valid value when ordering is not correct", ctx do
      RB.delay(1, 3000)

      # Should update all replicas to have a value of 1
      Replica.update(ctx.replica, {:increment})

      # Except the value or replicas(1) is still 0 because of delay
      Process.sleep(1000)
      assert RB.query(:value) == [1, 0, 1]

      # With replicas(1) increment, it should compare itself
      # with other replicas and determine that it must take its value
      # from the other ones
      replica1 = R.replicas(1)
      Replica.update(replica1, {:increment})

      Process.sleep(1000)
      assert RB.query(:value) == [2, 2, 2]

      # With the arrival of the delayed message, replicas(1) should
      # determine that the resulting value of the delayed message
      # is smaller than its current value which leads to ignoring it
      Process.sleep(1000)
      assert RB.query(:value) == [2, 2, 2]
    end
  end

  describe "when broadcasting with deliberate failures" do
    setup do
      {:ok, registry_pid} = R.start_link(:pn_counter, 3)
      {:ok, _} = RB.start_link(registry_pid)
      {:ok, replica: R.replicas(0)}
    end

    test "fails to deliver update to a replica", ctx do
      RB.fail(1)

      Replica.update(ctx.replica, {:increment})

      Process.sleep(1000)
      assert RB.query(:value) == [1, 0, 1]
    end

    test "eventually resolves to a valid value", ctx do
      RB.fail(1)

      # Will fail to deliver to replicas(1)
      Replica.update(ctx.replica, {:increment})

      # Will deliver to replicas(1)
      Replica.update(ctx.replica, {:increment})
      Process.sleep(1000)

      assert RB.query(:value) == [2, 2, 2]
    end
  end
end
