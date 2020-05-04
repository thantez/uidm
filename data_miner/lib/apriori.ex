defmodule DataMiner.Apriori do
  @moduledoc """
  Documentation for `Apriori`.
  """

  # minimum support percent
  @min_supp 5
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
    transactions_length_calculation(transactions)
    |> remove_low_frequencies(frequencies)
    |> make_sub_itemset()
    |> calculate_itemsets_frequency(transactions)
    |> merge_frequents(frequents)
    |> apriori(transactions)
  end

  def merge_frequents({frequencies, frequents}, pre_frequents) do
    {frequencies, pre_frequents ++ frequents}
  end

  def calculate_itemsets_frequency({itemsets, frequents}, transactions) do
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

    {frequencies, frequents}
  end

  def make_sub_itemset(frequencies) do
    Stream.with_index(frequencies, 1)
    |> Enum.each(fn {{itemset, _}, index} ->
      {_, remained_frequencies} = Enum.split(frequencies, index)

      spawn_link(fn -> make_itemset_loop() end)
      |> send({itemset, remained_frequencies, self()})
    end)

    # Enum.each(frequencies, fn {itemset, frequency} ->
    #   frequencies_except_itemset = frequencies -- [{itemset, frequency}]

    #   spawn_link(fn -> make_itemset_loop() end)
    #   |> send({itemset, frequencies_except_itemset, self()})
    # end)

    wait_for_end([], [], length(frequencies))
  end

  def wait_for_end(frequencies, frequents, 0), do: {frequencies, frequents}

  def wait_for_end(frequencies, frequents, counter) do
    receive do
      {:end, zero_frequencies, pre_frequents} ->
        new_frequencies = frequencies ++ zero_frequencies
        new_frequents = pre_frequents ++ frequents
        wait_for_end(new_frequencies, new_frequents, counter - 1)
    end
  end

  def make_itemset_loop() do
    receive do
      {base_itemset, frequencies, parent_pid} ->
        sub_itemsets =
          frequencies
          |> Stream.map(fn {itemset, frequency} ->
            sub_itemset = make_itemset(base_itemset, itemset)
            {sub_itemset, 0}
          end)
          |> Enum.filter(fn {itemset, _} -> itemset != nil end)

        frequent_itemset =
          if sub_itemsets == [] do
            [base_itemset]
          else
            []
          end

        send(parent_pid, {:end, sub_itemsets, frequent_itemset})
    end
  end

  def make_itemset(itemset_1, itemset_2) do
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
    |> Enum.reduce(%{}, fn [item, freq], acc -> Map.put(acc, [item], freq) end)
  end

  def import_transactions do
    Path.expand("../transactions.result")
    |> import_file()
    |> Stream.run()
  end

  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split(&1, "|"))
  end
end
