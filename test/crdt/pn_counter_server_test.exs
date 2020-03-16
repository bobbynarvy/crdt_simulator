defmodule CRDT.PNCounterServerTest do
  use ExUnit.Case
  doctest CRDT.PNCounterServer
  import CRDT.PNCounterServer

  setup do
    {_, pid} = start_link({2, 0})
    {:ok, pid: pid}
  end

  test "initializes a counter" do
    {status, _} = start_link({2, 0})
    assert status == :ok
  end

  test "queries the payload of the counter", ctx do
    assert query(ctx.pid, :payload) == {[0, 0], [0, 0]}
  end

  test "queries the value of the counter", ctx do
    assert query(ctx.pid, :value) == 0
  end

  test "increments the value of the counter", ctx do
    assert update(ctx.pid, {:increment}) == :ok
    assert query(ctx.pid, :value) == 1
  end

  test "decrements the value of the counter", ctx do
    update(ctx.pid, {:decrement})
    assert query(ctx.pid, :value) == -1
  end

  test "a counter compares its value with another", ctx do
    {:ok, pid2} = start_link({2, 1})
    update(ctx.pid, {:increment})
    assert compare(ctx.pid, pid2) == false
  end

  test "a counter merges its payload with another counter's", ctx do
    {:ok, pid2} = start_link({2, 1})

    update(ctx.pid, {:increment})

    assert merge(ctx.pid, pid2) == :ok
    assert query(ctx.pid, :value) == 1

    assert merge(pid2, ctx.pid) == :ok
    assert query(pid2, :value) == 1

    update(pid2, {:increment})
    merge(ctx.pid, pid2)
    assert query(ctx.pid, :value) == 2

    update(ctx.pid, {:increment})
    assert query(ctx.pid, :value) == 3

    update(pid2, {:decrement})
    assert query(pid2, :value) == 1

    merge(ctx.pid, pid2)
    assert query(ctx.pid, :value) == 2
  end
end
