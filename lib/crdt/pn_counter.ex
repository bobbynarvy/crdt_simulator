defmodule CRDT.PNCounter do
  @moduledoc """
  Implements a Positive-Negative Counter CRDT
  """

  @doc """
  Initializes the counter with a tuple consisting of
  two sub-counters: a list of increments and a list of decrements. 
  Each consists of n elements, the value of which corresponds
  to the number of times an increment/decrement 
  has been done for a given replica.
  """
  def initialize(n) do
    zeroes = for _ <- 1..n, do: 0
    {zeroes, zeroes}
  end

  @doc """
  Increments the counter for a given replica
  by incrementing the value of the positive sub-counter given
  the replica's position
  """
  def update({:increment, counter, position}) do
    {positives, negatives} = counter
    updated = List.update_at(positives, position, &(&1 + 1))
    {updated, negatives}
  end

  @doc """
  Decrements the counter for a given replica
  by incrementing the value of the negative sub-counter given
  the replica's position
  """
  def update({:decrement, counter, position}) do
    {positives, negatives} = counter
    updated = List.update_at(negatives, position, &(&1 + 1))
    {positives, updated}
  end

  @doc """
  Returns the current value of the given counter
  """
  def query({:value, counter}) do
    {positives, negatives} = counter
    Enum.sum(positives) - Enum.sum(negatives)
  end

  @doc """
  Compares two counters by checking if all sub-counter values of a counter
  are less than or equal to those of the corresponding counter's
  """
  def compare(counter1, counter2) do
    {p1, n1} = counter1
    {p2, n2} = counter2
    all_smaller_values?(p1, p2) and all_smaller_values?(n1, n2)
  end

  @doc """
  Merges two counters
  """
  def merge(counter1, counter2) do
    {p1, n1} = counter1
    {p2, n2} = counter2
    {merge_part(p1, p2), merge_part(n1, n2)}
  end

  # Checks if all of a sub-counter's values are less than or equal
  # to another's
  defp all_smaller_values?(list1, list2) do
    List.zip([list1, list2])
    |> Enum.filter(fn {x1, x2} -> x1 > x2 end)
    |> (fn results -> length(results) == 0 end).()
  end

  # Merges two sub-counters by getting the higher value of
  # the values of both sub-counters in the same position
  defp merge_part(list1, list2) do
    List.zip([list1, list2])
    |> Enum.map(fn {x1, x2} -> Enum.max([x1, x2]) end)
  end
end
