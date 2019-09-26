defmodule AbitTest do
  use ExUnit.Case
  doctest Abit

  test "merge of 2 atomics bit arrays returns left reference" do
    ref_a = :atomics.new(2, signed: false)
    ref_b = :atomics.new(2, signed: false)

    ref_a |> :atomics.put(1, 321)
    ref_b |> :atomics.put(2, 123)

    merged_ref = Abit.merge(ref_a, ref_b)

    assert merged_ref == ref_a
  end

  test "merge of 2 atomics bit arrays merges values" do
    ref_a = :atomics.new(2, signed: false)
    ref_b = :atomics.new(2, signed: false)

    ref_a |> :atomics.put(1, 321)
    ref_a |> :atomics.put(2, 1)
    ref_b |> :atomics.put(2, 122)

    merged_ref = Abit.merge(ref_a, ref_b)

    assert 321 = :atomics.get(merged_ref, 1)
    assert 123 = :atomics.get(merged_ref, 2)
  end
end
