defmodule AprioriTest do
  use ExUnit.Case
  doctest DataMiner.Apriori
  alias DataMiner.Apriori

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
    result = Apriori.merger(["c", "b", "a"], ["d", "b", "a"])
    expected_itemset = ["d", "c", "b", "a"]
    assert result == expected_itemset

    result2 = Apriori.merger(["a"], ["b"])
    expected_itemset2 = ["b", "a"]
    assert result2 == expected_itemset2
  end

  test "make itemset from a base itemset: wrong data" do
    result = Apriori.merger(["a", "d", "c"], ["a", "b", "d"])
    expected_itemset = []
    assert result == expected_itemset
  end

  test "merge itemsets test" do
    supported_frequency = [
      {["a"], 2},
      {["b"], 3},
      {["c"], 3},
      {["e"], 3}
    ]

    expected_frequency =
      MapSet.new([
        MapSet.new(["a", "b"]),
        MapSet.new(["a", "c"]),
        MapSet.new(["a", "e"]),
        MapSet.new(["b", "c"]),
        MapSet.new(["b", "e"]),
        MapSet.new(["c", "e"])
      ])

    assert expected_frequency == MapSet.new(Apriori.merge_itemsets(supported_frequency, []))
  end

  test "merge itemsets test round 2" do
    supported_frequency = [
      {["c", "a"], 2},
      {["c", "b"], 2},
      {["e", "b"], 3},
      {["e", "c"], 2}
    ]

    expected_frequency = [
      MapSet.new(["e", "c", "b"])
    ]

    assert expected_frequency == Apriori.merge_itemsets(supported_frequency, [])
  end

  test "calculate itemsets frequency" do
    itemsets = [
      MapSet.new(["a", "b"]),
      MapSet.new(["a", "c"]),
      MapSet.new(["a", "e"]),
      MapSet.new(["b", "c"]),
      MapSet.new(["b", "e"]),
      MapSet.new(["c", "e"])
    ]

    expected_result =
      MapSet.new([
        {["a", "b"], 1},
        {["a", "c"], 2},
        {["a", "e"], 1},
        {["b", "c"], 2},
        {["b", "e"], 3},
        {["c", "e"], 2}
      ])

    assert expected_result ===
             MapSet.new(Apriori.calculate_itemsets_frequency(itemsets, @transactions))
  end

  test "apriori algorithm" do
    expected_frequents =
      MapSet.new([
        {["a"], 2},
        {["b"], 3},
        {["c"], 3},
        {["e"], 3},
        {["a", "c"], 2},
        {["b", "c"], 2},
        {["b", "e"], 3},
        {["c", "e"], 2},
        {["b", "c", "e"], 2}
      ])

    assert MapSet.new(
             Apriori.apriori(
               @frequencies,
               [],
               @transactions,
               @min_supp,
               length(@transactions)
             )
             |> List.flatten()
           ) ==
             expected_frequents
  end

  test "write" do
    assert Apriori.apriori(
             @frequencies,
             [],
             @transactions,
             @min_supp,
             length(@transactions)
           )
           |> List.flatten()
           |> Apriori.export_frequents() == :ok
  end

  # test "test main" do
  #   assert Apriori.main() == :ok
  # end
end
