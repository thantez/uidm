defmodule DataMiner.Apriori do
  @moduledoc """
  Documentation for `Apriori` Algorithm Implementation.
  """

  @transactions_file Path.expand("../data/transactions_items.txt")
  @frequencies_file Path.expand("../data/items_frequencies.txt")
  @result_save_file Path.expand("../results/apriori_frequents.txt")

  @doc """
  Main function for run algorithm with minimum support.

  This function will get minimum support as input.

  This number is expressed as a percentage.

  At the end of function result of `Apriori` algorithm will
  save to a file.
  """
  def main(min_supp) do
    transactions = import_transactions()
    frequencies = import_frequencies()

    start = Time.utc_now()

    apriori(frequencies, [], transactions, min_supp, length(transactions))
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

    Enum.each(frequents, fn {itemset, frequency} ->
      Enum.each(itemset, fn item ->
        IO.write(file, "#{item} | ")
      end)

      IO.write(file, "#{frequency}\n")
    end)
  end

  @doc """
  Implementation of eclat algorithm, this function will return any frequent itemset.

  ## Examples

      iex> DataMiner.Eclat.eclat([{[:a], MapSet.new([2])}, {[:b], MapSet.new([2])}], [], 0.1, 3)
      [[{[:b, :a], #MapSet<[2]>}], [{[:a], #MapSet<[2]>}, {[:b], #MapSet<[2]>}]]

  """
  def apriori([], frequents, _, _, _) do
    IO.inspect("ends")
    frequents
  end

  def apriori(frequencies, frequents, transactions, min_supp, transactions_length) do
    IO.inspect("apriori!")

    supported_itemsets = remove_low_frequencies(transactions_length, frequencies, min_supp)

    new_frequencies =
      supported_itemsets
      |> merge_itemsets([])
      |> calculate_itemsets_frequency(transactions)

    apriori(
      new_frequencies,
      [supported_itemsets | frequents],
      transactions,
      min_supp,
      transactions_length
    )
  end

  @doc """
  This function will calculate frequency of any itemset by see itemset frequency inside transactions.

  ## Examples

      iex> DataMiner.Apriori.calculate_itemsets_frequency([["a", "b"], ["a", "c"]] |> Enum.map(&MapSet.new(&1)), [["a", "c", "d"], ["b", "c", "e"], ["a", "b", "c", "e"], ["b", "e"]] |> Enum.map(&MapSet.new(&1)))
      [{["a", "b"], 1}, {["a", "c"], 2}]

  """
  def calculate_itemsets_frequency(itemsets, transactions) do
    IO.inspect("calculating #{length(itemsets)}")

    start = Time.utc_now()

    result =
      itemsets
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(fn itemset ->
        frequency =
          transactions
          |> Enum.reduce(0, fn transaction, acc ->
            if MapSet.subset?(itemset, transaction) do
              acc + 1
            else
              acc
            end
          end)

        {MapSet.to_list(itemset), frequency}
      end)
      |> Enum.to_list()

    endt = Time.utc_now()
    IO.inspect("time of frequency calculating: #{Time.diff(endt, start)}s")
    result
  end

  @doc """
  This function will merge a list of itemsets to a list of sub itemsets.
  So input is a list of itemsets and output is a list of merged itemsets.

  """
  def merge_itemsets([], merged_itemsets), do: merged_itemsets |> List.flatten()

  def merge_itemsets([{base_itemset, _} | tail], merged_list) do
    merged =
      tail
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(fn {itemset, _} ->
        MapSet.new(merger(base_itemset, itemset))
      end)
      |> Flow.partition()
      |> Flow.filter(fn itemset -> itemset != MapSet.new() end)
      |> Enum.to_list()

    merge_itemsets(tail, [merged | merged_list])
  end

  @doc """
  merger will merge two itemsets.

   ## Examples

      iex> DataMiner.Apriori.merger([1, 2, 3], [4, 2, 3])
      [4, 1, 2, 3]

  """
  def merger([base_item | tail_base_itemset], [item | tail_itemset]) do
    if tail_base_itemset == tail_itemset do
      [item | [base_item | tail_base_itemset]]
    else
      []
    end
  end

  @doc """
  When itemsets merged succesfully, we should pipe them into `remove_low_frequencies`
  that will remove all of itemsets that size of their transactions are lower that minimum support.

  This is for downward closers!

  """
  def remove_low_frequencies(transactions_length, frequencies, min_supp) do
    frequencies
    |> Enum.filter(fn {_item, frequency} ->
      support(frequency, transactions_length) >= min_supp
    end)
  end

  @doc """
  support will calculate support of an itemset by its frequency
  """
  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  @doc """
  import frequencies file.
  """
  def import_frequencies do
    @frequencies_file
    |> import_file()
    |> Enum.reduce(%{}, fn [item, freq], acc ->
      Map.put(acc, [item], String.to_integer(Atom.to_string(freq)))
    end)
  end

  @doc """
  import transactions file.
  """
  def import_transactions do
    @transactions_file
    |> import_file()
    |> Enum.map(fn transaction -> MapSet.new(transaction) end)
  end

  @doc """
  import file.
  """
  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn line ->
      String.split(line, "|")
      |> Enum.filter(fn word -> word != "" end)
      |> Enum.map(fn item -> String.to_atom(item) end)
    end)
    |> Stream.drop(1)
  end
end
