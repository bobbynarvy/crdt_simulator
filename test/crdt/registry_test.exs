defmodule CRDT.RegistryTest do
  use ExUnit.Case
  doctest CRDT.Registry
  alias CRDT.Registry, as: R

  test "initializes a set of replicas" do
    {status, _} = R.start_link(:pn_counter, 3)
    assert status == :ok
    assert List.length(R.replicas()) == 3
  end

  test "keeps track of the CRDT type" do
    type = R.crdt_type()
    assert type == :pn_counter
  end

  test "gets a replica pid by index" do
    {status, _} = R.replicas(0)
    assert status == :ok
  end

  test "stops all replicas" do
    {_, pid} = R.replicas(0)
    {status} = R.stop_replicas()
    assert Process.alive?(pid) == false
    assert status == :ok
    assert List.length(R.replicas()) == 0
  end
end
