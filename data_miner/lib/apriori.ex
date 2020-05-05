defmodule DataMiner.Apriori do
  @moduledoc """
  Documentation for `Apriori`.
  """

  @min_supp 2
  @doc """
  Main function for apriori algorithm.
  """
  def main do
    transactions = import_transactions()
    frequencies = import_frequencies()

    apriori(frequencies, [], transactions, @min_supp, length(transactions))
    |> List.flatten()
    |> export_frequents()
  end

  def export_frequents(frequents) do
    {:ok, file} = File.open(Path.expand("../frequents.result"), [:write])

    Enum.each(frequents, fn {itemset, frequency} ->
      Enum.each(itemset, fn item ->
        IO.write(file, "#{item} | ")
      end)

      IO.write(file, "#{frequency}\n")
    end)
  end

  def apriori([], frequents, _, _, _) do
    IO.inspect("ends")
    frequents
  end

  def apriori(frequencies, frequents, transactions, min_supp, transactions_length) do
    IO.inspect("apriori!")

    supported_itemsets = remove_low_frequencies(transactions_length, frequencies, min_supp)

    new_frequencies =
      supported_itemsets
      |> merge_itemsets()
      |> calculate_itemsets_frequency(transactions)

    apriori(
      new_frequencies,
      [supported_itemsets | frequents],
      transactions,
      min_supp,
      transactions_length
    )
  end

  def calculate_itemsets_frequency(itemsets, transactions) do
    IO.inspect("calculating #{length(itemsets)}")

    itemsets
    |> Task.async_stream(
      fn itemset ->
        frequency =
          transactions
          |> Task.async_stream(fn transaction ->
            MapSet.subset?(itemset, transaction)
          end)
          |> Stream.filter(fn {:ok, result} -> result end)
          |> Enum.count()

        {MapSet.to_list(itemset), frequency}
      end,
      ordered: false
    )
    |> Enum.reduce([], fn {:ok, merged}, merged_list -> [merged | merged_list] end)
  end

  def merge_itemsets(itemsets) do
    IO.inspect("merging")

    Stream.with_index(itemsets, 1)
    |> Task.async_stream(fn {{base_itemset, _}, index} ->
      Stream.drop(itemsets, index)
      |> Stream.map(fn {itemset, _} ->
        MapSet.new(merger(base_itemset, itemset))
      end)
      |> Enum.filter(fn itemset -> itemset != MapSet.new() end)
    end)
    |> Enum.reduce([], fn {:ok, merged}, merged_list -> [merged | merged_list] end)
    |> List.flatten()
  end

  def merger(itemset_1, itemset_2) do
    {last_item_1, remained_itemset_1} = List.pop_at(itemset_1, -1)
    {last_item_2, remained_itemset_2} = List.pop_at(itemset_2, -1)

    if remained_itemset_1 == remained_itemset_2 do
      remained_itemset_1 ++ [last_item_1, last_item_2]
    else
      []
    end
  end

  def transactions_length_calculation(transactions) do
    length(transactions)
  end

  def remove_low_frequencies(transactions_length, frequencies, min_supp) do
    frequencies
    |> Enum.filter(fn {_item, frequency} ->
      support(frequency, transactions_length) >= min_supp
    end)
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  def import_frequencies do
    Path.expand("../frequencies.csv")
    |> import_file()
    |> Enum.reduce(%{}, fn [item, freq], acc ->
      Map.put(acc, [item], String.to_integer(freq))
    end)
  end

  def import_transactions do
    Path.expand("../transactions.result")
    |> import_file()
    |> Enum.map(fn transaction -> MapSet.new(transaction) end)
  end

  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split(&1, "|"))
    |> Stream.drop(1)
  end
end
