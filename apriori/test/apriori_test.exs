defmodule AprioriTest do
  use ExUnit.Case
  doctest Apriori

  @transactions [["a", "b", "d"], ["b", "c", "e"], ["a", "b", "c", "e"], ["b", "e"]]
  @frequencies [
    [["a"], 2],
    [["b"], 3],
    [["c"], 3],
    [["d"], 1],
    [["e"], 3]
  ]
  @transactions_length 4

  test "check support calculation" do
    assert Apriori.support(3, 6) == 50
    assert Apriori.support(4, 10) == 40
    assert Apriori.support(129_327_323, 1_224_343_234) == 10.562995686877787
  end

  test "transactions length calculator" do
    assert Apriori.transactions_length_calculation(@transactions) == @transactions_length
  end

  test "low frequency removes ckeck" do
    supported_frequencies = Apriori.remove_low_frequencies(@transactions_length, @frequencies)
    expected_frequencies = [[["a"], 2], [["b"], 3], [["c"], 3], [["e"], 3]]
    assert supported_frequencies == expected_frequencies
  end

  test "make itemset from a base itemset: correct data" do
    result = Apriori.make_itemset(["a", "b", "c"], ["a", "b", "d"])
    expected_itemset = ["a", "b", "c", "d"]
    assert result == expected_itemset

    result2 = Apriori.make_itemset(["a"], ["b"])
    expected_itemset2 = ["a", "b"]
    assert result2 == expected_itemset2
  end

  test "make itemset from a base itemset: wrong data" do
    result = Apriori.make_itemset(["a", "d", "c"], ["a", "b", "d"])
    expected_itemset = nil
    assert result == expected_itemset
  end

  test "make sub itemset test" do
    supported_frequency = [
      [["a"], 2],
      [["b"], 3],
      [["c"], 3],
      [["e"], 3]
    ]

    expected_frequency =
      {[
         [["a", "b"], 0],
         [["a", "c"], 0],
         [["a", "e"], 0],
         [["b", "c"], 0],
         [["b", "e"], 0],
         [["c", "e"], 0]
       ], []}

    assert Apriori.make_sub_itemset(supported_frequency) == expected_frequency
  end
end
