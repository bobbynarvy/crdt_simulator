defmodule CRDT.PNCounter do
  def initialize(n) do
    zeroes = for _ <- 1..n, do: 0
    {zeroes, zeroes}
  end

  def update({:increment, counter, position}) do
    {positives, negatives} = counter
    updated = List.update_at(positives, position, &(&1 + 1))
    {updated, negatives}
  end

  def update({:decrement, counter, position}) do
    {positives, negatives} = counter
    updated = List.update_at(negatives, position, &(&1 + 1))
    {positives, updated}
  end

  def query({:value, counter}) do
    {positives, negatives} = counter
    Enum.sum(positives) - Enum.sum(negatives)
  end

  def compare(counter1, counter2) do
    {p1, n1} = counter1
    {p2, n2} = counter2
    all_smaller_values?(p1, p2) and all_smaller_values?(n1, n2)
  end

  def merge(counter1, counter2) do
    {p1, n1} = counter1
    {p2, n2} = counter2
    {merge_part(p1, p2), merge_part(n1, n2)}
  end

  defp all_smaller_values?(list1, list2) do
    List.zip([list1, list2])
    |> Enum.filter(fn {x1, x2} -> x1 > x2 end)
    |> (fn results -> length(results) == 0 end).()
  end

  defp merge_part(list1, list2) do
    List.zip([list1, list2])
    |> Enum.map(fn {x1, x2} -> Enum.max([x1, x2]) end)
  end
end
