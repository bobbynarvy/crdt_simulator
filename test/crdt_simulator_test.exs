defmodule CRDTSimulatorTest do
  use ExUnit.Case
  doctest CRDTSimulator

  test "greets the world" do
    assert CRDTSimulator.hello() == :world
  end
end
