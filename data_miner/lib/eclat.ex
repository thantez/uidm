defmodule DataMiner.Eclat do
  @min_supp 2
  @transactions_file Path.expand("../transactions.result")

  # def export_frequents(frequents) do
  #   {:ok, file} = File.open(Path.expand("../frequents.result"), [:write])

  #   Enum.each(frequents, fn {itemset, frequency} ->
  #     Enum.each(itemset, fn item ->
  #       IO.write(file, "#{item} | ")
  #     end)

  #     IO.write(file, "#{frequency}\n")
  #   end)
  # end

  # ----------------------------------------------------------------------------------
  # ----------------------------------------------------------------------------------

  def main do
    transactions = import_transactions()

    itemsets =
      transactions
      |> Stream.with_index()
      |> transactios_to_eclat_form()

    # |> IO.inspect(label: "Eclat formation has been done.")

    start = Time.utc_now()

    result =
      eclat(itemsets, [], @min_supp, length(transactions))
      |> List.flatten()
      |> Enum.map(fn {itemset, transaction} -> "#{itemset} | #{MapSet.size(transaction)}" end)

    endt = Time.utc_now()
    IO.inspect("total time: #{Time.diff(endt, start)}s")

    result
  end

  def eclat([], frequents, _, _) do
    IO.inspect("ends")
    frequents
  end

  def eclat(itemsets, frequents, min_supp, transactions_length) do
    IO.inspect("eclat!")

    supported_itemsets = remove_low_frequencies(itemsets, min_supp, transactions_length)

    supported_itemsets
    |> merge_itemsets([])
    |> eclat([supported_itemsets | frequents], min_supp, transactions_length)
  end

  def merge_itemsets([], merged_itemsets), do: merged_itemsets |> List.flatten()

  def merge_itemsets([base_itemset | tail], merged_list) do
    merged =
      tail
      |> Flow.from_enumerable()
      |> Flow.map(fn itemset ->
        merger(base_itemset, itemset)
      end)
      |> Flow.filter(fn itemset -> itemset != nil end)
      |> Enum.to_list()

    merge_itemsets(tail, [merged | merged_list])
  end

  def merger(
        {[base_item | tail_base_itemset], base_transactions},
        {[item | tail_itemset], transactions}
      ) do
    # IO.inspect("merge for #{base_item} && #{item}")

    if tail_base_itemset == tail_itemset do
      {[item | [base_item | tail_base_itemset]],
       MapSet.intersection(base_transactions, transactions)}
    else
      nil
    end
  end

  def remove_low_frequencies(itemsets, min_supp, transactions_length) do
    itemsets
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_item, transactions} ->
      support(MapSet.size(transactions), transactions_length) >= min_supp
    end)
    |> Enum.to_list()
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  def transactios_to_eclat_form(transactions) do
    Enum.reduce(transactions, %{}, fn {transaction, index}, items ->
      items_with_index = Map.put(items, :index, index)

      Enum.reduce(transaction, items_with_index, fn item, items ->
        item_tids =
          Map.get(items, [item], MapSet.new())
          |> MapSet.put(items.index)

        Map.put(items, [item], item_tids)
      end)
    end)
    |> Enum.filter(fn
      {:index, _} -> false
      _ -> true
    end)
  end

  def import_transactions do
    Path.expand(@transactions_file)
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
