# CRDTSimulator

This project simulates several [CRDTs](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) using Elixir processes as replicas that hold and share state with each other, and eventually merge to a single consistent state.

## Usage

Upon starting an **iex** session with this project (`iex -S mix`), start by creating a cluster of replicas:

```elixir
# Create a cluster of 3 Positive-Negative Counter replicas
CRDTSimulator.start_link({:pn_counter, 3})
```

Note: CRDT identifiers can be chosen from the [implemented varieties](#crdt-varieties).

Several internal processes will be launched that essentially watch over replica updates and broadcast them to other replicas.

Specific replica pids can be accessed by index and updated:

```elixir
replica_0 = CRDT.Registry.replicas(0)
CRDT.Replica.update(replica_0, {:increment})
```

The user is prompted when updates have been propagated throughout the cluster.

Update broadcast delays to specific replicas can be simulated:

```elixir
# The next update to the first replica will appear after 3 seconds
# once the next update to another replica is triggered
CRDT.ReplicaBroadcaster.delay(0, 3000)
```

Update broadcast failures can also be simulated:

```elixir
# The next update to the first replica will fail. Any new updates
# will only be applied upon merge of a new update
CRDT.ReplicaBroadcaster.fail(0)
```


### CRDT Varieties

|CRDT                                 |Identifier   |Update operation(s)                            |
|-------------------------------------|-------------|-----------------------------------------------|
|Grow-only Counter (G-Counter)        |:g_counter   |`{:increment}`                                 |
|Positive-Negative Counter (Counter)  |:pn_counter  |`{:increment}`, `{:decrement}`                 |
|Grow-only Set (G-set)                |:g_set       |`{:add, *element*}`                            |
