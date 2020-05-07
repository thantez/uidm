defmodule EclatTest do
  use ExUnit.Case
  doctest DataMiner.Eclat
  alias DataMiner.Eclat

  @transactions [["a", "c", "d"], ["b", "c", "e"], ["a", "b", "c", "e"], ["b", "e"]]
                |> Enum.map(&MapSet.new(&1))
  @frequencies %{
    ["a"] => 2,
    ["b"] => 3,
    ["c"] => 3,
    ["d"] => 1,
    ["e"] => 3
  }
  @transactions_length 4
  @min_supp 2 / 5 * 100
end
