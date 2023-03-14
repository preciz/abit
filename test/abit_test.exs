defmodule AbitTest do
  use ExUnit.Case
  doctest Abit

  test "set_bit_at" do
    ref = :atomics.new(10, signed: false)

    0..9
    |> Enum.each(fn index ->
      0..63
      |> Enum.each(fn pos ->
        bit = index * 64 + pos

        ref |> Abit.set_bit_at(bit, 1)

        assert :atomics.get(ref, index + 1) == round(:math.pow(2, pos))

        ref |> Abit.set_bit_at(bit, 0)
      end)
    end)
  end

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

  test "intersect of 2 atomics bit arrays returns left reference" do
    ref_a = :atomics.new(2, signed: false)
    ref_b = :atomics.new(2, signed: false)

    ref_a |> :atomics.put(1, 321)
    ref_a |> :atomics.put(2, 1)
    ref_b |> :atomics.put(2, 122)

    intersect_ref = Abit.intersect(ref_a, ref_b)

    assert intersect_ref == ref_a
  end

  test "intersect of 2 atomics bit arrays intersect values" do
    ref_a = :atomics.new(2, signed: false)
    ref_b = :atomics.new(2, signed: false)

    ref_a |> :atomics.put(1, 321)
    ref_a |> :atomics.put(2, 1)
    ref_b |> :atomics.put(2, 123)

    intersect_ref = Abit.intersect(ref_a, ref_b)

    assert 0 = :atomics.get(intersect_ref, 1)
    assert 1 = :atomics.get(intersect_ref, 2)
  end

  test "hamming distance of 2 atomics bit arrays" do
    ref_l = :atomics.new(10, signed: false)
    ref_r = :atomics.new(10, signed: false)
    assert 0 == Abit.hamming_distance(ref_l, ref_r)

    ref_l |> :atomics.put(1, 7)

    assert 3 == Abit.hamming_distance(ref_l, ref_r)

    ref_r |> :atomics.put(1, 7)

    assert 0 == Abit.hamming_distance(ref_l, ref_r)

    ref_r |> :atomics.put(2, 1024)

    assert 1 == Abit.hamming_distance(ref_l, ref_r)
  end

  test "hamming_distance raises if sizes of atomics are non equal" do
    assert_raise ArgumentError, fn ->
      ref_l = :atomics.new(1, signed: false)
      ref_r = :atomics.new(2, signed: false)

      Abit.hamming_distance(ref_l, ref_r)
    end
  end
end
