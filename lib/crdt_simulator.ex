defmodule CRDTSimulator do
  use Supervisor

  def start_link({type, num_reps}) do
    IO.puts("Creating a #{type} cluster with #{num_reps} replicas...")
    Supervisor.start_link(__MODULE__, {type, num_reps}, name: __MODULE__)
  end

  @impl true
  def init(params) do
    children = [
      {CRDT.Registry, params},
      %{id: CRDT.ReplicaBroadcaster, start: {CRDT.ReplicaBroadcaster, :start_link, []}},
      %{id: CRDT.Poller, start: {CRDT.Poller, :start_link, []}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def stop_cluster() do
  end

  def info() do
    [registry, broadcaster] = Supervisor.which_children(__MODULE__)
    {_, registry_pid, _, _} = registry
    {_, broadcaster_pid, _, _} = broadcaster

    %{
      registry: registry_pid,
      replica_broadcaster: broadcaster_pid
    }
  end
end
