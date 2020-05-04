defmodule DataMiner.Eclat do
  alias DataMiner.Node

  @min_supp 5
  @transactions_file Path.expand("../transactions.result")

  def main do
    transactions =
      import_transactions()
      |> Enum.map(fn a -> a end)

    nodes =
      transactions
      |> Stream.with_index()
      |> transactios_to_eclat_form()
      |> make_family()

    IO.inspect(length(nodes))

    eclat(nodes, length(transactions), 1)
    |> IO.inspect()
  end

  def eclat(nodes, transactions_length, depth) do
    nodes
    |> Enum.filter(fn %{itemset: itemset} -> length(itemset) == depth end)
    |> DataMiner.remove_low_frequencies(transactions_length, @min_supp)
    |> make_sub_itemset()
  end

  def make_sub_itemset(nodes) do
    Stream.with_index(nodes, 1)
    |> Enum.each(fn {node, index} ->
      {_, next_nodes} = Enum.split(nodes, index)

      spawn_link(fn -> make_itemset_loop() end)
      |> send({node, next_nodes, self()})
    end)

    wait_for_end([], length(nodes))
  end

  def wait_for_end(nodes, 0), do: nodes

  def wait_for_end(nodes, counter) do
    receive do
      {:end, zero_nodes} ->
        new_nodes = nodes ++ zero_nodes
        wait_for_end(new_nodes, counter - 1)
    end
  end

  def make_itemset_loop() do
    receive do
      {base_node, nodes, parent_pid} ->
        sub_itemsets =
          nodes
          |> Stream.map(fn node -> make_itemset(base_node, node) end)
          |> Enum.filter(fn
            nil -> false
            _ -> true
          end)

        send(parent_pid, {:end, sub_itemsets})
    end
  end

  def make_itemset(
        %Node{itemset: itemset_1, value: value_1} = node_1,
        %Node{itemset: itemset_2, value: value_2} = node_2
      ) do
    {last_item_1, remained_itemset_1} = List.pop_at(itemset_1, -1)
    {last_item_2, remained_itemset_2} = List.pop_at(itemset_2, -1)

    if remained_itemset_1 == remained_itemset_2 do
      itemset = remained_itemset_1 ++ [last_item_1, last_item_2]
      value = MapSet.intersection(value_1, value_2)
      Node.birth(node_1, node_2, itemset, value)
    else
      nil
    end
  end

  def make_family(transactions) do
    transactions
    |> Enum.map(fn {itemset, value} ->
      %Node{itemset: itemset, value: value, frequency: MapSet.size(value)}
    end)
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
    main_transactions =
      Path.expand(@transactions_file)
      |> import_file()
  end

  def import_file(file_address) do
    File.stream!(file_address)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split(&1, "|"))
  end
end
