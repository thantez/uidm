defmodule DataMiner.Apriori do
  @moduledoc """
  Documentation for `Apriori`.
  """

  # minimum support percent
  @min_supp 0.000001
  # minimum confidence percent
  @min_conf 70

  @doc """
  Main function for apriori algorithm.
  """
  def main do
    transactions = import_transactions()
    frequencies = import_frequencies()

    apriori({frequencies, []}, transactions)
  end

  def apriori({frequencies, frequents}, _) when frequencies == %{} do
    frequents
  end

  def apriori({frequencies, frequents}, transactions) do
    supported_itemsets =
      transactions_length_calculation(transactions)
      |> remove_low_frequencies(frequencies)

    new_frequencies =
      supported_itemsets
      |> merge_itemsets()
      |> calculate_itemsets_frequency(transactions)

    apriori({new_frequencies, frequents ++ supported_itemsets}, transactions)
  end

  def calculate_itemsets_frequency(itemsets, transactions) do
    # TODO: concurency
    frequencies =
      for transaction <- transactions, {itemset, _} <- itemsets do
        diff = itemset -- transaction

        if diff == [] do
          itemset
        end
      end
      |> Enum.frequencies()
      |> Map.delete(nil)

    frequencies
  end

  def merge_itemsets(itemsets) do
    Stream.with_index(itemsets, 1)
    |> Enum.each(fn {{itemset, _}, index} ->
      tail_itemsets = Stream.drop(itemsets, index)

      spawn_link(fn -> merge_itemsets_receiver() end)
      |> send({itemset, tail_itemsets, self()})
    end)

    wait_for_end([], length(itemsets))
  end

  def wait_for_end(merged_until_now, 0), do: merged_until_now

  def wait_for_end(merged_until_now, counter) do
    receive do
      {:end, merged_itemsets} ->
        wait_for_end(merged_until_now ++ merged_itemsets, counter - 1)
    end
  end

  def merge_itemsets_receiver() do
    receive do
      {base_itemset, itemsets, parent_pid} ->
        sub_itemsets =
          itemsets
          |> Stream.map(fn {itemset, _} ->
            {merger(base_itemset, itemset), 0}
          end)
          |> Enum.filter(fn {itemset, _} -> itemset != nil end)

        send(parent_pid, {:end, sub_itemsets})
    end
  end

  def merger(itemset_1, itemset_2) do
    {last_item_1, remained_itemset_1} = List.pop_at(itemset_1, -1)
    {last_item_2, remained_itemset_2} = List.pop_at(itemset_2, -1)

    if remained_itemset_1 == remained_itemset_2 do
      remained_itemset_1 ++ [last_item_1, last_item_2]
    else
      nil
    end
  end

  def transactions_length_calculation(transactions) do
    length(transactions)
  end

  def remove_low_frequencies(transactions_length, frequencies) do
    frequencies
    |> Enum.filter(fn {_item, frequency} ->
      support(frequency, transactions_length) >= @min_supp
    end)
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  def import_frequencies do
    Path.expand("../frequencies.csv")
    |> import_file()
    |> Enum.reduce(%{}, fn [item, freq], acc -> Map.put(acc, [item], String.to_integer(freq)) end)
  end

  def import_transactions do
    Path.expand("../transactions.result")
    |> import_file()
    |> Enum.to_list()
  end

  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split(&1, "|"))
    |> Stream.drop(1)
  end
end
