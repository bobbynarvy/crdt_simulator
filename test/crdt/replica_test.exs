defmodule CRDT.ReplicaTest do
  use ExUnit.Case
  import CRDT.Replica
  doctest CRDT.Replica

  test "initializes a replica" do
    {status, _} = start_link({:pn_counter, 3, 1})
    assert status == :ok
  end

  test "returns an error given an inexistent replica type" do
    {status, _} = start_link({:doesnt_exist})
    assert status == :error
  end

  test "queries the payload of a replica" do
    {_, counter} = start_link({:pn_counter, 3, 1})
    assert query(counter, :payload) == {[0, 0, 0], [0, 0, 0]}
  end

  test "updates a replica" do
    {:ok, counter} = start_link({:pn_counter, 3, 1})
    :ok = update(counter, {:increment})
    assert query(counter, :payload) == {[0, 1, 0], [0, 0, 0]}
  end

  test "queries the value of a replica" do
    {:ok, counter} = start_link({:pn_counter, 3, 1})
    update(counter, {:increment})
    assert query(counter, :value) == 1
  end

  test "compares two replicas" do
    {:ok, counter1} = start_link({:pn_counter, 3, 1})
    update(counter1, {:increment})
    {:ok, counter2} = start_link({:pn_counter, 3, 2})
    update(counter2, {:increment})
    assert compare(counter1, counter2) == false
  end

  test "returns error when replicas don't have the same type" do
    {:ok, pid1} = start_link({:pn_counter, 3, 1})
    {:ok, pid2} = start_link({:g_counter, 3, 1})
    {status, error} = compare(pid1, pid2)
    assert status == :error
    assert error == "The replicas do not have the same type."
  end

  test "merges two replicas" do
    {:ok, counter1} = start_link({:pn_counter, 3, 1})
    update(counter1, {:increment})
    {:ok, counter2} = start_link({:pn_counter, 3, 2})
    update(counter2, {:increment})
    merge(counter1, counter2)
    merge(counter2, counter1)
    assert query(counter1, :value) == 2
    assert query(counter2, :value) == 2
  end

  test "publishes messages to subscribers" do
    test_pid = self()
    {_, replica} = start_link({:pn_counter, 3, 0})

    spawn(fn ->
      subscribe(replica, self())

      receive do
        :update -> send(test_pid, :updated)
      end
    end)

    update(replica, {:increment})

    result =
      receive do
        :updated -> :success
      end

    assert result == :success
  end
end
