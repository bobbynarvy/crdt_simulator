defmodule CRDT.PNCounterServerTest do
  use ExUnit.Case
  doctest CRDT.PNCounterServer
  import CRDT.PNCounterServer

  test "initializes a counter" do
    {status, _} = start_link(2, 0)
    assert status == :ok
  end

  test "queries the payload of the counter" do
    {:ok, pid} = start_link(2, 0)
    assert query(pid, :payload) == {[0, 0], [0, 0]}
  end

  test "queries the value of the counter" do
    {:ok, pid} = start_link(2, 0)
    assert query(pid, :value) == 0
  end

  test "increments the value of the counter" do
    {:ok, pid} = start_link(2, 0)
    assert update(pid, {:increment}) == :ok
    assert query(pid, :value) == 1
  end

  test "decrements the value of the counter" do
    {:ok, pid} = start_link(2, 0)
    update(pid, {:decrement})
    assert query(pid, :value) == -1
  end

  test "a counter compares its value with another" do
    {:ok, pid1} = start_link(2, 0)
    {:ok, pid2} = start_link(2, 1)
    update(pid1, {:increment})
    assert compare(pid1, pid2) == false
  end

  test "a counter merges its payload with another counter's" do
    {:ok, pid1} = start_link(2, 0)
    {:ok, pid2} = start_link(2, 1)

    update(pid1, {:increment})

    assert merge(pid1, pid2) == :ok
    assert query(pid1, :value) == 1

    assert merge(pid2, pid1) == :ok
    assert query(pid2, :value) == 1

    update(pid2, {:increment})
    merge(pid1, pid2)
    assert query(pid1, :value) == 2

    update(pid1, {:increment})
    assert query(pid1, :value) == 3

    update(pid2, {:decrement})
    assert query(pid2, :value) == 1

    merge(pid1, pid2)
    assert query(pid1, :value) == 2
  end
end
