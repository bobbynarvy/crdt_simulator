defmodule CRDT.TPSetServerTest do
  use ExUnit.Case
  import CRDT.TPSetServer

  setup do
    {:ok, pid} = start_link({})
    {:ok, pid2} = start_link({})
    {:ok, pid: pid, pid2: pid2}
  end

  test "initialize a two-phase set" do
    {status, _} = start_link({})
    assert status == :ok
  end

  test "queries the payload of the two-phase set", ctx do
    {add, remove} = query(ctx.pid, :payload)

    assert MapSet.equal?(add, MapSet.new())
    assert MapSet.equal?(remove, MapSet.new())
  end

  test "adds and element and looks up a value in the two-phase set", ctx do
    update(ctx.pid, {:add, :hello})
    {add, _} = query(ctx.pid, :payload)

    assert MapSet.equal?(add, MapSet.new([:hello]))
    assert query(ctx.pid, {:lookup, :hello}) == true
  end

  test "removes an element from a two-phase set", ctx do
    update(ctx.pid, {:add, :hello})
    update(ctx.pid, {:remove, :hello})
    {add, remove} = query(ctx.pid, :payload)

    assert MapSet.equal?(add, MapSet.new([:hello]))
    assert MapSet.equal?(remove, MapSet.new([:hello]))
    assert query(ctx.pid, {:lookup, :hello}) == false
  end

  test "queries the value of the two-phase set", ctx do
    update(ctx.pid, {:add, :hello})
    update(ctx.pid, {:add, :world})
    update(ctx.pid, {:remove, :hello})
    IO.inspect(query(ctx.pid, :payload))

    assert MapSet.equal?(query(ctx.pid, :value), MapSet.new([:world]))
  end

  test "compares two two-phase sets", ctx do
    update(ctx.pid2, {:add, :world})
    assert compare(ctx.pid, ctx.pid2) == true

    update(ctx.pid, {:add, :hello})
    assert compare(ctx.pid, ctx.pid2) == false
  end

  test "merges two two-phase sets", ctx do
    update(ctx.pid, {:add, :hello})
    update(ctx.pid2, {:add, :world})
    merge(ctx.pid, ctx.pid2)

    assert query(ctx.pid, {:lookup, :hello}) == true
    assert query(ctx.pid, {:lookup, :world}) == true
  end
end
