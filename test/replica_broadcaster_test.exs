defmodule CRDT.ReplicaBroadcasterTest do
  use ExUnit.Case
  alias CRDT.ReplicaBroadcaster, as: RB

  describe "when initializing" do
    test "returns ok" do
      {status, _} = RB.start_link(:pn_counter, 3)
      assert status == :ok
      assert List.length(RB.replicas()) == 3
    end

    test "throws error there are less than 3 replicas" do
      {status, _} = RB.start_link(:pn_counter, 1)
      assert status == :error
    end
  end

  setup do
    :ok = RB.start_link(:pn_counter, 3)
    {:ok}
  end

  test "keeps track of the CRDT type" do
    type = RB.crdt_type()
    assert type == :pn_counter
  end

  test "gets a replica pid by index" do
    pid = RB.replicas(0)
    assert Process.alive?(pid) == true
  end

  test "stops all replicas" do
    pid = RB.replicas(0)
    status = RB.stop_replicas()
    assert Process.alive?(pid) == false
    assert status == :ok
    assert List.length(RB.replicas()) == 0
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
