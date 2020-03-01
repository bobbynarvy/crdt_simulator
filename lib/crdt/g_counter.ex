defmodule CRDT.GCounter do
  @moduledoc """
  Implements a Grow-only Counter CRDT
  """

  @doc """
  Initializes the CRDT with a list on n elements
  with 0 as a value
  """
  def initialize(n) do
    for _ <- 1..n, do: 0
  end

  @doc """
  Increments the element of the CRDT at a given
  position
  """
  def update({:increment, set, position}) do
    List.update_at(set, position, &(&1 + 1))
  end

  @doc """
  Returns the current value of the CRDT
  """
  def query({:value, set}) do
    set
  end

  @doc """
  Compares the current value of the CRDT
  with the value of the CRDT from another replica
  """
  def compare(x, y) do
    List.zip([x, y])
    |> Enum.map(fn pair -> elem(pair, 0) <= elem(pair, 1) end)
    |> Enum.filter(fn smaller? -> smaller? end)
    |> (fn results -> length(results) > 0 end).()
  end

  @doc """
  Merges the value of the current CRDT
  with that of another CRDT replica
  """
  def merge(x, y) do
    List.zip([x, y])
    |> Enum.map(fn pair -> Tuple.to_list(pair) end)
    |> Enum.map(fn pair -> Enum.max(pair) end)
  end
end
