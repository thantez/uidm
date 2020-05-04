defmodule DataMiner.Node do
  defstruct parents: MapSet.new(), itemset: [], value: [], frequency: 0, children: []

  def birth(father, mother, itemset, value) do
    child = %__MODULE__{itemset: itemset, value: value}

    fathers_children = List.insert_at(father.children, -1, child)
    mothers_children = List.insert_at(mother.children, -1, child)
    Map.put(father, :children, fathers_children)
    Map.put(mother, :children, mothers_children)

    Map.put(child, :parents, MapSet.new([father, mother]))
  end

  def growth(child, frequency) do
    Map.put(child, :frequency, frequency)
  end

  def death(child) do
    father = child.father
    mother = child.mother

    fathers_children = father.children
    mothers_children = mother.children

    fathers_new_children = List.delete(fathers_children, child)
    mothers_new_children = List.delete(mothers_children, child)

    Map.put(father, :children, fathers_new_children)
    Map.put(mother, :children, mothers_new_children)
  end
end
