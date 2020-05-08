defmodule DataMiner do
  def main(["--min=" <> min]) do
    min_supp = String.to_float(min)
    IO.inspect("start eclat")
    DataMiner.Eclat.main(min_supp)
    IO.inspect("start apriori")
    DataMiner.Apriori.main(min_supp)
    IO.inspect("done")
  end
end
