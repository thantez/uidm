defmodule DataMinerTest do
  use ExUnit.Case
  doctest DataMiner

  test "greets the world" do
    assert DataMiner.hello() == :world
  end
end
