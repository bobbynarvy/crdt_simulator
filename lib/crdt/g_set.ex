defmodule CRDT.GSet do
  @moduledoc """
  Implements operations related to a Grow-only set CRDT
  """

  import MapSet

  @doc """
  Initializes an empty set
  """
  def initialize() do
    new([])
  end

  @doc """
  Adds an element to the set
  """
  def update({:add, set, elem}) do
    put(set, elem)
  end

  @doc """
  Checks if an element is a member of a set
  """
  def query({:lookup, set, elem}) do
    member?(set, elem)
  end

  @doc """
  Checks if a set is the subset of another set
  """
  def compare(set1, set2) do
    subset?(set1, set2)
  end

  @doc """
  Merges two sets
  """
  def merge(set1, set2) do
    union(set1, set2)
  end
end
