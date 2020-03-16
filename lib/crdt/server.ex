defmodule CRDT.Server do
  @callback start_link(tuple) :: {:ok, term} | {:error, String.t()}

  @callback query(pid, atom) :: term

  @callback update(pid, tuple) :: :ok | {:error, String.t()}

  @callback compare(pid, pid) :: boolean

  @callback merge(pid, pid) :: :ok | {:error, String.t()}
end
