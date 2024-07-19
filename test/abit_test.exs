defmodule AbitTest do
  use ExUnit.Case, async: true
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

  test "to_list returns a flat list of bits" do
    ref = :atomics.new(2, signed: false)
    # 5 in binary is 101
    :atomics.put(ref, 1, 5)
    # 3 in binary is 11
    :atomics.put(ref, 2, 3)

    result = Abit.to_list(ref)

    expected_first = List.duplicate(0, 61) ++ [1, 0, 1]
    expected_second = List.duplicate(0, 62) ++ [1, 1]

    assert result == expected_first ++ expected_second
  end

  test "to_list correctly returns bits for the value 1024" do
    ref = :atomics.new(1, signed: false)
    :atomics.put(ref, 1, 1024)

    result = Abit.to_list(ref)

    assert result == List.duplicate(0, 53) ++ [1] ++ List.duplicate(0, 10)
  end

  describe "bit_count/1" do
    test "returns correct bit count for atomics with arity 1" do
      ref = :atomics.new(1, signed: false)
      assert Abit.bit_count(ref) == 64
    end

    test "returns correct bit count for atomics with arity 3" do
      ref = :atomics.new(3, signed: false)
      assert Abit.bit_count(ref) == 192
    end
  end

  describe "bit_position/1" do
    test "returns correct position for first bit" do
      assert Abit.bit_position(0) == {1, 0}
    end

    test "returns correct position for bit within first atomic" do
      assert Abit.bit_position(63) == {1, 63}
    end

    test "returns correct position for first bit of second atomic" do
      assert Abit.bit_position(64) == {2, 0}
    end

    test "returns correct position for large bit index" do
      assert Abit.bit_position(1000) == {16, 40}
    end
  end

  describe "set_bits_count/1" do
    test "returns 0 for an empty atomics reference" do
      ref = :atomics.new(1, signed: false)
      assert Abit.set_bits_count(ref) == 0
    end

    test "returns correct count for atomics with arity 1 and all bits set" do
      ref = :atomics.new(1, signed: false)
      # Binary: 111
      :atomics.put(ref, 1, 7)
      assert Abit.set_bits_count(ref) == 3
    end

    test "returns correct count for atomics with arity 1 and no bits set" do
      ref = :atomics.new(3, signed: false)
      # Binary: 101
      :atomics.put(ref, 1, 5)
      # Binary: 11
      :atomics.put(ref, 2, 3)
      # Binary: 1000
      :atomics.put(ref, 3, 8)
      assert Abit.set_bits_count(ref) == 5
    end

    test "handles large numbers correctly" do
      ref = :atomics.new(2, signed: false)
      # All 64 bits set
      :atomics.put(ref, 1, 0xFFFFFFFFFFFFFFFF)
      # Lower 32 bits set
      :atomics.put(ref, 2, 0x00000000FFFFFFFF)
      assert Abit.set_bits_count(ref) == 96
    end
  end
end
