defmodule DataMiner.Eclat do
  @moduledoc """
  Documentation for `Eclat` Algorithm Implementation.
  """
  @transactions_file Path.expand("../data/transactions_items.txt")
  @result_save_file Path.expand("../results/eclat_frequents.txt")

  @doc """
  Main function for run algorithm with minimum support.

  This function will get minimum support as input.

  This number is expressed as a percentage.

  At the end of function result of `Eclat` algorithm will
  save to a file.

  """
  def main(min_supp) do
    transactions = import_transactions()

    itemsets =
      transactions
      |> transactios_to_eclat_form()

    start = Time.utc_now()

    eclat(itemsets, [], min_supp, length(transactions))
    |> List.flatten()
    |> export_frequents()

    endt = Time.utc_now()
    IO.inspect("total time: #{Time.diff(endt, start)}s")
  end

  @doc """
  Export frequents will export all frequent itemsets to a file.
  """
  def export_frequents(frequents) do
    {:ok, file} = File.open(@result_save_file, [:write])

    Enum.each(frequents, fn {itemset, transactions} ->
      itemset
      |> Enum.each(fn item ->
        IO.write(file, "#{item} | ")
      end)

      IO.write(file, "#{MapSet.size(transactions)}\n")
    end)
  end

  @doc """
  Implementation of eclat algorithm, this function will return any frequent itemset.

  ## Examples

      iex> DataMiner.Eclat.eclat([{[:a], MapSet.new([2])}, {[:b], MapSet.new([2])}], [], 0.1, 3)
      [[{[:b, :a], #MapSet<[2]>}], [{[:a], #MapSet<[2]>}, {[:b], #MapSet<[2]>}]]

  """
  def eclat([], frequents, _, _) do
    IO.inspect("ends")
    frequents
  end

  def eclat(itemsets, frequents, min_supp, transactions_length) do
    IO.inspect("eclat!")

    supported_itemsets = remove_low_frequencies(itemsets, min_supp, transactions_length)
    IO.inspect("supported")

    supported_itemsets
    |> merge_itemsets()
    |> eclat([supported_itemsets | frequents], min_supp, transactions_length)
  end

  @doc """
  This function will merge a list of itemsets to a list of sub itemsets.
  So input is a list of itemsets and output is a list of merged itemsets.

  `note: Ccommented code is a parallel code for merging.`

  ## Examples

      iex> DataMiner.Eclat.merge_itemsets([{[2, 1], MapSet.new([2])}, {[3, 1], MapSet.new([2])}])
      [{[3, 2, 1], #MapSet<[2]>}]

  """
  def merge_itemsets(itemsets) do
    IO.inspect("merging #{length(itemsets)}")

    # itemsets
    # |> Stream.with_index(1)
    # |> Flow.from_enumerable()
    # |> Flow.partition()
    # |> Flow.flat_map(fn {{[base_item | tail_base_itemset], base_transactions}, index} ->
    #   itemsets
    #   |> Stream.drop(index)
    #   |> Stream.filter(fn {[_ | tail_itemset], _} -> tail_itemset == tail_base_itemset end)
    #   |> Enum.map(fn {[item | _], transactions} ->
    #     {[item | [base_item | tail_base_itemset]],
    #      MapSet.intersection(base_transactions, transactions)}
    #   end)
    # end)
    # |> Enum.to_list()

    itemsets
    |> Stream.with_index(1)
    |> Stream.flat_map(fn {{[base_item | tail_base_itemset], base_transactions}, index} ->
      itemsets
      |> Stream.drop(index)
      |> Stream.filter(fn {[_ | tail_itemset], _} -> tail_itemset == tail_base_itemset end)
      |> Stream.map(fn {[item | _], transactions} ->
        {[item | [base_item | tail_base_itemset]],
         MapSet.intersection(base_transactions, transactions)}
      end)
      |> Enum.to_list()
    end)
    |> Enum.to_list()
  end

  @doc """
  This function will merge an itemset with another itemset.

  What is merge itemsets and make sub itemset?
  if we have `a = [1, 2, 4]` and `b = [1, 2, 5]`
  then merge of them will be: `result = [1, 2, 4, 5]`

  `a` and `b` can merge because of (0 .. k-1)th items in their lists are similar.

  In this module for avoiding of list overhead, we merge lists by (1 .. k)th items. if `a = [2, 1]` and `b = [3, 1]`
  then merge of them with this algorithm will be: `result = [3, 2, 1]`

  ## Examples

      iex> DataMiner.Eclat.merge_itemsets([{[2, 1], MapSet.new([2])}, {[3, 1], MapSet.new([2])}])
      [{[3, 2, 1], #MapSet<[2]>}]

  """
  def merger({base_item, base_transactions}, {item, transactions}, group_tail) do
    {[item | [base_item | group_tail]], MapSet.intersection(base_transactions, transactions)}
  end

  @doc """
  When itemsets merged succesfully, we should pipe them into `remove_low_frequencies`
  that will remove all of itemsets that size of their transactions are lower that minimum support.

  This is for downward closers!

  ## Examples

      iex> DataMiner.Eclat.remove_low_frequencies([{[:a], MapSet.new([1, 2, 3])}, {[:b], MapSet.new([1])}], 50, 3)
      [{[:a], #MapSet<[1, 2, 3]>}]

  """
  def remove_low_frequencies(itemsets, min_supp, transactions_length) do
    itemsets
    |> Enum.filter(fn {_item, transactions} ->
      support(MapSet.size(transactions), transactions_length) >= min_supp
    end)
    |> IO.inspect()
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  @doc """
  This function will get main transactions and return eclat form of that.

  Eclat form is a `map` that show transactions of an item that it is inside them!

  ## Examples

      iex> DataMiner.Eclat.transactios_to_eclat_form([["1", "2"], ["2", "4"], ["1", "5"], ["1", "6", "7", "3", "1", "2", "9"]])
      {[:"1"] => #MapSet<[0, 2, 3]>, [:"2"] => #MapSet<[0, 1, 3]>, [:"3"] => #MapSet<[3]>, [:"4"] => #MapSet<[1]>, [:"5"] => #MapSet<[2]>, [:"6"] => #MapSet<[3]>, [:"7"] => #MapSet<[3]>, [:"9"] => #MapSet<[3]>}
     
  """
  def transactios_to_eclat_form(transactions) do
    transactions
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn {transaction, index}, items ->
      Enum.frequencies(transaction)
      |> Map.new(fn {item, _} -> {[String.to_atom(item)], MapSet.new([index])} end)
      |> Map.merge(items, fn _k, v1, v2 -> MapSet.union(v1, v2) end)
    end)
  end

  @doc """
  import transactions file.
  """
  def import_transactions do
    Path.expand(@transactions_file)
    |> import_file()
    |> Enum.to_list()
  end

  @doc """
  Import file.
  """
  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn line -> String.split(line, "|") |> Enum.filter(fn word -> word != "" end) end)
    |> Stream.drop(1)
  end
end
