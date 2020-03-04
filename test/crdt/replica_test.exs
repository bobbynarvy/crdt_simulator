defmodule CRDT.ReplicaTest do
  use ExUnit.Case
  import CRDT.Replica
  doctest CRDT.Replica

  test "initializes a replica" do
    {status, _} = initialize({:pn_counter, 3, 1})
    assert status == :ok
  end

  test "returns an error given an inexistent replica type" do
    {status, _} = initialize({:doesnt_exist})
    assert status == :error
  end

  test "queries the payload of a replica" do
    {_, counter} = initialize({:pn_counter, 3, 1})
    assert Replica.query(counter, {:payload}) == {[0, 0, 0], [0, 0, 0]}
  end

  test "updates a replica" do
    {:ok, counter} = initialize({:pn_counter, 3, 1})
    {:ok} = Replica.update(counter, {:increment})
    assert Replica.query(counter, {:payload}) == {[0, 1, 0], [0, 0, 0]}
  end

  test "queries the value of a replica" do
    {:ok, counter} = initialize({:pn_counter, 3, 1})
    Replica.update(counter, {:increment})
    assert Replica.query(counter, {:value}) == 1
  end

  test "compares two replicas" do
    {:ok, counter1} = initialize({:pn_counter, 3, 1})
    Replica.update(counter1, {:increment})
    {:ok, counter2} = initialize({:pn_counter, 3, 2})
    Replica.update(counter2, {:increment})
    assert Replica.compare(counter1, counter2) == false
  end

  test "merges two replicas" do
    {:ok, counter1} = initialize({:pn_counter, 3, 1})
    Replica.update(counter1, {:increment})
    {:ok, counter2} = initialize({:pn_counter, 3, 2})
    Replica.update(counter2, {:increment})
    Replica.merge(counter1, counter2)
    Replica.merge(counter2, counter1)
    assert Replica.query(counter1, {:value}) == 2
    assert Replica.query(counter2, {:value}) == 2
  end
end
