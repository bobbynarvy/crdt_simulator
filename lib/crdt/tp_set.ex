defmodule CRDT.TPSet do
  @moduledoc """
  Implements operations related to a Two-Phase Set CRDT
  """

  import MapSet

  @doc """
  Initializes a two-phase set
  """
  def initialize(), do: {new(), new()}

  @doc """
  Adds an element to the two-phase set
  """
  def update({:add, set, elem}) do
    {add, remove} = set
    {put(add, elem), remove}
  end

  @doc """
  Removes an element from the two-phase set
  """
  def update({:remove, set, elem}) do
    {add, remove} = set

    if query({:lookup, set, elem}) == true do
      {add, put(add, elem)}
    else
      {add, remove}
    end
  end

  @doc """
  Checks if an element exists in the two-phase set
  """
  def query({:lookup, set, elem}) do
    {add, remove} = set
    member?(add, elem) and !member?(remove, elem)
  end

  @doc """
  Checks if a two-phase set is the subset of another two-phase set
  """
  def compare(set1, set2) do
    {add1, remove1} = set1
    {add2, remove2} = set2

    subset?(add1, add2) and subset?(remove1, remove2)
  end

  @doc """
  Merges two two-phase sets
  """
  def merge(set1, set2) do
    {add1, remove1} = set1
    {add2, remove2} = set2

    {union(add1, add2), union(remove1, remove2)}
  end
end
