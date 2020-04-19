defmodule CRDT.Server do
  @moduledoc """
  Behaviour that defines the expected functions
  that a CRDT Server must implement
  """

  @callback start_link(tuple) :: {:ok, term} | {:error, String.t()}

  @callback query(pid, atom | tuple) :: term

  @callback update(pid, tuple) :: :ok | {:error, String.t()}

  @callback compare(pid, pid) :: boolean

  @callback merge(pid, pid) :: :ok | {:error, String.t()}
end
