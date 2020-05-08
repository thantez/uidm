defmodule DataMiner do
  def main(_args) do
    IO.inspect("start apriori")
    DataMiner.Apriori.main()
    IO.inspect("start eclat")
    DataMiner.Eclat.main()
    IO.inspect("done")
  end
end
