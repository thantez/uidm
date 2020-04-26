defmodule AprioriTest do
  use ExUnit.Case
  doctest Apriori

  test "check transaction import function" do
    assert Apriori.import_transactions() == :ok
  end
end
