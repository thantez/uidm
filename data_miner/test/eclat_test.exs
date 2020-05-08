defmodule EclatTest do
  use ExUnit.Case
  doctest DataMiner.Eclat
  alias DataMiner.Eclat

  @transactions [["a", "c", "d"], ["b", "c", "e"], ["a", "b", "c", "e"], ["b", "e"]]
                |> Enum.map(&MapSet.new(&1))
  @transactions_length 4
  @min_supp 2 / 5 * 100

  test "eclat form" do
    expected = %{
      ["a"] => MapSet.new([0, 2]),
      ["b"] => MapSet.new([1, 2, 3]),
      ["c"] => MapSet.new([0, 1, 2]),
      ["d"] => MapSet.new([0]),
      ["e"] => MapSet.new([1, 2, 3])
    }

    assert expected == Eclat.transactios_to_eclat_form(@transactions)
  end

  test "low frequencies" do
    input = %{
      ["a"] => MapSet.new([0, 2]),
      ["b"] => MapSet.new([1, 2, 3]),
      ["c"] => MapSet.new([0, 1, 2]),
      ["d"] => MapSet.new([0]),
      ["e"] => MapSet.new([1, 2, 3])
    }

    expected = [
      {["a"], MapSet.new([0, 2])}
    ]
  end
end
