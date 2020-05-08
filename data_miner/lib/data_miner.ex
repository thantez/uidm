defmodule DataMiner do
  @moduledoc """
  `DataMiner` has twi main module: `Apriori` and `Eclat`. see their documentation.
  """

  @doc """
  Main function for escript.
  """
  def main(["--min=" <> min]) do
    min_supp = String.to_float(min)
    IO.inspect("start eclat")
    DataMiner.Eclat.main(min_supp)
    IO.inspect("start apriori")
    DataMiner.Apriori.main(min_supp)
    IO.inspect("done")
  end
end
