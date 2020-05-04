defmodule AprioriTest do
  use ExUnit.Case
  doctest DataMiner.Apriori
  alias DataMiner.Apriori

  @transactions [["a", "c", "d"], ["b", "c", "e"], ["a", "b", "c", "e"], ["b", "e"]]
  @frequencies %{
    ["a"] => 2,
    ["b"] => 3,
    ["c"] => 3,
    ["d"] => 1,
    ["e"] => 3
  }
  @transactions_length 4
  @min_supp 2 / 5 * 100

  test "check support calculation" do
    assert Apriori.support(3, 6) == 50
    assert Apriori.support(129_327_323, 1_224_343_234) == 10.562995686877787
  end

  test "transactions length calculator" do
    assert Apriori.transactions_length_calculation(@transactions) == @transactions_length
  end

  test "low frequency removes ckeck" do
    supported_frequencies =
      Apriori.remove_low_frequencies(@transactions_length, @frequencies, @min_supp)

    expected_frequencies = [{["a"], 2}, {["b"], 3}, {["c"], 3}, {["e"], 3}]
    assert supported_frequencies == expected_frequencies
  end

  test "make itemset from a base itemset: correct data" do
    result = Apriori.merger(["a", "b", "c"], ["a", "b", "d"])
    expected_itemset = ["a", "b", "c", "d"]
    assert result == expected_itemset

    result2 = Apriori.merger(["a"], ["b"])
    expected_itemset2 = ["a", "b"]
    assert result2 == expected_itemset2
  end

  test "make itemset from a base itemset: wrong data" do
    result = Apriori.merger(["a", "d", "c"], ["a", "b", "d"])
    expected_itemset = nil
    assert result == expected_itemset
  end

  test "merge itemsets test" do
    supported_frequency = [
      {["a"], 2},
      {["b"], 3},
      {["c"], 3},
      {["e"], 3}
    ]

    expected_frequency = [
      {["a", "b"], 0},
      {["a", "c"], 0},
      {["a", "e"], 0},
      {["b", "c"], 0},
      {["b", "e"], 0},
      {["c", "e"], 0}
    ]

    assert expected_frequency == Apriori.merge_itemsets(supported_frequency)
  end

  test "merge itemsets test round 2" do
    supported_frequency = [
      {["a", "c"], 2},
      {["b", "c"], 2},
      {["b", "e"], 3},
      {["c", "e"], 2}
    ]

    expected_frequency = [
      {["b", "c", "e"], 0}
    ]

    assert expected_frequency == Apriori.merge_itemsets(supported_frequency)
  end

  test "calculate itemsets frequency" do
    itemsets = [
      {["a", "b"], 0},
      {["a", "c"], 0},
      {["a", "e"], 0},
      {["b", "c"], 0},
      {["b", "e"], 0},
      {["c", "e"], 0}
    ]

    expected_result = %{
      ["a", "b"] => 1,
      ["a", "c"] => 2,
      ["a", "e"] => 1,
      ["b", "c"] => 2,
      ["b", "e"] => 3,
      ["c", "e"] => 2
    }

    assert expected_result === Apriori.calculate_itemsets_frequency(itemsets, @transactions)
  end

  test "apriori algorithm" do
    expected_frequents = [
      {["a"], 2},
      {["b"], 3},
      {["c"], 3},
      {["e"], 3},
      {["a", "c"], 2},
      {["b", "c"], 2},
      {["b", "e"], 3},
      {["c", "e"], 2},
      {["b", "c", "e"], 2}
    ]

    assert Apriori.apriori({@frequencies, MapSet.new()}, @transactions, @min_supp) ==
             MapSet.new(expected_frequents)
  end

  # test "write" do
  #   assert Apriori.apriori({@frequencies, MapSet.new()}, @transactions, @min_supp)
  #          |> MapSet.to_list()
  #          |> Apriori.export_frequents() == :ok
  # end

  test "test main" do
    assert Apriori.main() == :ok
  end
end
