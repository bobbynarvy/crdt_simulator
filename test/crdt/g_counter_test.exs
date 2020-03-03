defmodule CRDT.GCounterTest do
  use ExUnit.Case
  doctest CRDT.GCounter
  alias CRDT.GCounter, as: GC

  test "initializes 5 elements" do
    assert GC.initialize(5) == [0, 0, 0, 0, 0]
  end

  test "updates the set" do
    assert GC.update({:increment, [0, 0, 0], 2}) == [0, 0, 1]
  end

  test "returns tha value" do
    assert GC.query({:value, [1, 2, 3]}) == 6
  end

  test "compares two sets" do
    assert GC.compare([0, 1], [0, 0]) == true
  end

  test "merges two sets" do
    assert GC.merge([1, 0], [0, 1]) == [1, 1]
  end
end
