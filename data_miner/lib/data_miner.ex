defmodule DataMiner do
  @moduledoc """
  Documentation for `DataMiner`.
  """

  def transactions_length_calculation(transactions) do
    length(transactions)
  end

  def remove_low_frequencies(nodes, transactions_length, min_supp) do
    nodes
    |> Enum.filter(fn %{frequency: frequency} ->
      IO.inspect(support(frequency, transactions_length))
      support(frequency, transactions_length) >= min_supp
    end)
  end

  def support(item_frequency, transactions_length) do
    item_frequency / transactions_length * 100
  end
end
