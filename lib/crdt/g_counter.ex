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
    Enum.sum(set)
  end

  @doc """
  Compares the current value of the CRDT
  with the value of the CRDT from another replica
  """
  def compare(x, y) do
    List.zip([x, y])
    |> Enum.filter(fn {x, y} -> x <= y end)
    |> (fn results -> length(results) > 0 end).()
  end

  @doc """
  Merges the value of the current CRDT
  with that of another CRDT replica
  """
  def merge(x, y) do
    List.zip([x, y])
    |> Enum.map(fn {x, y} -> Enum.max([x, y]) end)
  end
end
