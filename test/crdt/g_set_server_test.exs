defmodule CRDT.GSetServerTest do
  use ExUnit.Case
  import CRDT.GSetServer

  setup do
    {:ok, pid} = start_link({})
    {:ok, pid2} = start_link({})
    {:ok, pid: pid, pid2: pid2}
  end

  test "initialize a set" do
    {status, _} = start_link({})
    assert status == :ok
  end

  test "queries the payload of the set", ctx do
    assert MapSet.equal?(query(ctx.pid, :payload), MapSet.new())
  end

  test "adds and element and looks up a value in the set", ctx do
    update(ctx.pid, {:add, :hello})
    assert query(ctx.pid, {:lookup, :hello}) == true
  end

  test "compares two counters", ctx do
    update(ctx.pid2, {:add, :new})
    assert compare(ctx.pid, ctx.pid2) == true
  end

  test "merges two counters", ctx do
    update(ctx.pid, {:add, :hello})
    update(ctx.pid2, {:add, :world})
    merge(ctx.pid, ctx.pid2)
    assert query(ctx.pid, {:lookup, :hello}) == true
    assert query(ctx.pid, {:lookup, :world}) == true
  end
end
