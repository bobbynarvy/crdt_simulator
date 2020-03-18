defmodule CRDT.GCounterServerTest do
  use ExUnit.Case
  import CRDT.GCounterServer

  setup do
    {:ok, pid} = start_link({2, 0})
    {:ok, pid2} = start_link({2, 1})
    {:ok, pid: pid, pid2: pid2}
  end

  test "initialize a counter" do
    {status, _} = start_link({2, 0})
    assert status == :ok
  end

  test "queries the payload of the counter", ctx do
    assert query(ctx.pid, :payload) = [0, 0]
  end

  test "queries the value of the counter", ctx do
    assert query(ctx.pid, :value) = 0
  end

  test "increments a counter" do
    status = update(ctx.pid, {:increment})
    assert status == :ok
    assert query(pid, :value) = 1
  end

  test "compares two counters" do
    update(ctx.pid2, {:increment})
    assert compare(pid, pid2) == true
  end

  test "merges two counters" do
    update(ctx.pid, {:increment})
    update(ctx.pid2, {:increment})
    assert query(ctx.pid, :payload) = [1, 1]
    assert query(pid, :value) == 2
  end
end
