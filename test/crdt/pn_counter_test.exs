defmodule CRDT.PNCounterTest do
  use ExUnit.Case
  doctest CRDT.PNCounter
  alias CRDT.PNCounter, as: PNC

  test "initializes the counter with 5 replicas" do
    assert PNC.initialize(5) == {[0, 0, 0, 0, 0], [0, 0, 0, 0, 0]}
  end

  test "increments the counter" do
    counter = {[0, 0, 0, 0, 0], [0, 0, 0, 0, 0]}
    assert PNC.update({:increment, counter, 2}) == {[0, 0, 1, 0, 0], [0, 0, 0, 0, 0]}
  end

  test "decrements the counter" do
    counter = {[0, 0, 0, 0, 0], [0, 0, 0, 0, 0]}
    assert PNC.update({:decrement, counter, 2}) == {[0, 0, 0, 0, 0], [0, 0, 1, 0, 0]}
  end

  test "returns the current value" do
    counter = {[5, 4, 3, 2, 1], [0, 1, 2, 3, 4]}
    assert PNC.query({:value, counter}) == 5
  end

  test "compares the value of 2 replicas" do
    counter1 = {[0, 0, 0], [0, 0, 1]}
    counter2 = {[0, 0, 0], [0, 0, 0]}
    assert PNC.compare(counter1, counter2) == true
  end

  test "compares the value of 2 replicas -- evaluates to false" do
    counter1 = {[0, 0, 0], [0, 0, 1]}
    counter2 = {[0, 0, 0], [2, 2, 2]}
    assert PNC.compare(counter1, counter2) == false
  end

  test "merges two replicas" do
    counter1 = {[0, 0, 0], [1, 2, 3]}
    counter2 = {[1, 2, 3], [0, 0, 0]}
    assert PNC.merge(counter1, counter2) == {[1, 2, 3], [1, 2, 3]}
  end
end
