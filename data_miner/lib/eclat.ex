defmodule DataMiner.Eclat do

  @transactions_file Path.expand("../data/transactions_items.txt")
  @result_save_file Path.expand("../results/eclat_frequents.txt")

  @min_supp 2

  def main do
    transactions = import_transactions()

    itemsets =
      transactions
      |> Stream.with_index()
      |> transactios_to_eclat_form()

    start = Time.utc_now()

    result =
      eclat(itemsets, [], @min_supp, length(transactions))
      |> List.flatten()
      |> export_frequents()

    endt = Time.utc_now()
    IO.inspect("total time: #{Time.diff(endt, start)}s")

    result
  end

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

  def merge_itemsets(itemsets) do
    itemsets
    |> Stream.with_index(1)
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.flat_map(fn {{[base_item | tail_base_itemset], base_transactions}, index} ->
      itemsets
      |> Stream.drop(index)
      |> Stream.filter(fn {[_ | tail_itemset], _} -> tail_itemset == tail_base_itemset end)
      |> Enum.map(fn {[item | _], transactions} ->
        {[item | [base_item | tail_base_itemset]],
         MapSet.intersection(base_transactions, transactions)}
      end)
    end)
    |> Enum.to_list()
  end

  def merger({base_item, base_transactions}, {item, transactions}, group_tail) do
    {[item | [base_item | group_tail]], MapSet.intersection(base_transactions, transactions)}
  end

  def remove_low_frequencies(itemsets, min_supp, transactions_length) do
    itemsets
    |> Enum.filter(fn {_item, transactions} ->
      support(MapSet.size(transactions), transactions_length) >= min_supp
    end)
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end

  def transactios_to_eclat_form(transactions) do
    Enum.reduce(transactions, %{}, fn {transaction, index}, items ->
      Enum.frequencies(transaction)
      |> Map.new(fn {item, _} -> {[item], MapSet.new([index])} end)
      |> Map.merge(items, fn _k, v1, v2 -> MapSet.union(v1, v2) end)
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
    |> Stream.map(fn line -> String.split(line, "|") |> Enum.filter(fn word -> word != "" end) end)
    |> Stream.drop(1)
  end
end
