defmodule CRDT.GSetTest do
  use ExUnit.Case
  doctest CRDT.GSet
  alias CRDT.GSet, as: GS
  import MapSet

  @empty_set new([])
  @hello_set new(["Hello"])
  @world_set new(["World"])

  test "initializes a set" do
    assert GS.initialize() == @empty_set
  end

  test "adds an element to a set" do
    assert GS.update({:add, @empty_set, "Hello"}) == @hello_set
  end

  test "looks up an element in the set" do
    assert GS.query({:lookup, @hello_set, "Hello"}) == true
  end

  test "compares two sets" do
    assert GS.compare(@empty_set, @hello_set) == true
    assert GS.compare(@hello_set, @world_set) == false
  end

  test "merges two sets" do
    assert GS.merge(@empty_set, @hello_set) == @hello_set
    assert GS.merge(@hello_set, @world_set) == new(["Hello", "World"])
  end
end
