defmodule CRDT.RegistryTest do
  use ExUnit.Case
  alias CRDT.Registry, as: R

  describe "when initializing" do
    test "returns ok" do
      {status, _} = R.start_link(:pn_counter, 3)
      assert status == :ok
      assert length(R.replicas()) == 3
    end

    test "throws error there are less than 3 replicas" do
      {status, _} = R.start_link(:pn_counter, 1)
      assert status == :error
    end
  end

  describe "when using" do
    setup do
      {:ok, pid} = R.start_link(:pn_counter, 3)
      {:ok, pid: pid}
    end

    test "keeps track of the CRDT type" do
      type = R.crdt_type()
      assert type == :pn_counter
    end

    test "gets a replica pid by index" do
      pid = R.replicas(0)
      assert Process.alive?(pid) == true
    end
  end
end
