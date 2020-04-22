defmodule CRDT.TPSetTest do
  use ExUnit.Case
  doctest CRDT.TPSet
  alias CRDT.TPSet, as: TPS
  import MapSet

  @empty_set new([])
  @hello_set new(["Hello"])
  @world_set new(["World"])

  setup do
    tp_set = TPS.initialize()
    {:ok, tp_set: tp_set}
  end

  test "initializes a two-phase set" do
    {add, remove} = TPS.initialize()
    assert equal?(add, @empty_set)
    assert equal?(remove, @empty_set)
  end

  test "looks up an element in the set", ctx do
    assert TPS.query({:lookup, ctx.tp_set, "Hello"}) == false
  end

  test "adds an element to a two-phase set", ctx do
    tp_set = TPS.update({:add, ctx.tp_set, "Hello"})
    {add, remove} = new_tp_set

    assert equal?(add, @hello_set)
    assert equal?(remove, @empty_set)
    assert TPS.query({:lookup, new_tp_set, "Hello"}) == true
  end

  test "removes an element from a two-phase set", ctx do
    added = TPS.update({:add, ctx.tp_set, "Hello"})
    removed = TPS.update({:remove, added, "Hello"})
    {add, remove} = removed

    assert equal?(add, @hello_set)
    assert equal?(remove, @hello_set)
    assert TPS.query({:lookup, removed, "Hello"}) == false
  end

  test "does not add when an element has already been removed" do
    added = TPS.update({:add, ctx.tp_set, "Hello"})
    removed = TPS.update({:remove, added, "Hello"})
    without_hello = TPS.update({:add, removed, "Hello"})

    assert TPS.query({:lookup, without_hello, "Hello"}) == false
  end

  test "does not remove an element that has not been added to a two-phase set", ctx do
    removed = TPS.update({:remove, ctx.tp_set, "Hello"})
    {add, remove} = removed

    assert equal?(add, @empty_set)
    assert equal?(remove, @empty_set)
    assert TPS.query({:lookup, removed, "Hello"}) == false
  end

  test "compares two two-phase sets" do
    tp_set1 = TPS.initialize()
    tp_set2 = TPS.initialize()

    assert TPS.compare(tp_set1, tp_set2) == true

    tp_set2_a = TPS.update({:add, tp_set2, "Hello"})

    assert TPS.compare(tp_set1, tp_set2_a) == true

    tp_set1_a = TPS.update({:add, tp_set1, "World"})

    assert TPS.compare(tp_set1_a, tp_set2_a) == false
  end

  test "merges two sets" do
    tp_set1 = TPS.initialize()
    tp_set2 = TPS.initialize()

    tp_set1_a = TPS.update({:add, tp_set1, "Hello"})
    tp_set2_a = TPS.update({:add, tp_set2, "World"})
    tp_set2_b = TPS.update({:remove, tp_set2_a, "World"})
    merged = TPS.merge(tp_set1_a, tp_set2_b)
    {add, remove} = merged

    assert equal?(add, new(["Hello", "World"]))
    assert equal?(remove, new(["World"]))
    assert TPS.query({:lookup, merged, "Hello"}) == true
    assert TPS.query({:lookup, merged, "World"}) == false
  end
end
