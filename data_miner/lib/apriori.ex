defmodule DataMiner.Apriori do
  @moduledoc """
  Documentation for `Apriori`.
  """
  require Logger

  @transactions_file Path.expand("../data/transactions_items.txt")
  @frequencies_file Path.expand("../data/items_frequencies.txt")
  @result_save_file Path.expand("../results/apriori_frequents.txt")

  @min_supp 0.001
  @doc """
  Main function for apriori algorithm.
  """
  def main do
    transactions = import_transactions()
    frequencies = import_frequencies()

    start = Time.utc_now()

    apriori(frequencies, [], transactions, @min_supp, length(transactions))
    |> List.flatten()
    |> export_frequents()

    endt = Time.utc_now()
    IO.inspect("total time: #{Time.diff(endt, start)}s")
  end

  def export_frequents(frequents) do
    {:ok, file} = File.open(@result_save_file, [:write])

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

  def merge_itemsets([], merged_itemsets), do: merged_itemsets |> List.flatten()

  def merge_itemsets([{base_itemset, _} | tail], merged_list) do
    Logger.debug("merge itemsets #{inspect(base_itemset)}")

    merged =
      tail
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(fn {itemset, _} ->
        MapSet.new(merger(base_itemset, itemset))
      end)
      |> Flow.filter(fn itemset -> itemset != MapSet.new() end)
      |> Enum.to_list()

    merge_itemsets(tail, [merged | merged_list])
  end

  def merger([base_item | tail_base_itemset], [item | tail_itemset]) do
    if tail_base_itemset == tail_itemset do
      [item | [base_item | tail_base_itemset]]
    else
      []
    end
  end

  def transactions_length_calculation(transactions) do
    length(transactions)
  end

  def remove_low_frequencies(transactions_length, frequencies, min_supp) do
    Logger.debug("remove low itemsets")

    frequencies
    |> Enum.filter(fn {_item, frequency} ->
      support(frequency, transactions_length) >= min_supp
    end)
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  def import_frequencies do
    @frequencies_file
    |> import_file()
    |> Enum.reduce(%{}, fn [item, freq], acc ->
      Map.put(acc, [String.to_atom(item)], String.to_integer(freq))
    end)
  end

  def import_transactions do
    @transactions_file
    |> import_file()
    |> Enum.map(fn transaction -> MapSet.new(transaction) end)
  end

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
