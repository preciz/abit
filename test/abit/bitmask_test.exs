defmodule Abit.BitmaskTest do
  use ExUnit.Case, async: true
  import Bitwise

  doctest Abit.Bitmask

  alias Abit.Bitmask

  test "set_bits_count" do
    assert 1 == Bitmask.set_bits_count(1)
    assert 1 == Bitmask.set_bits_count(2)
    assert 2 == Bitmask.set_bits_count(3)
    assert 1 == Bitmask.set_bits_count(8)
    assert 1 == Bitmask.set_bits_count(16)
    assert 4 == Bitmask.set_bits_count(15)
  end

  test "bit_at" do
    assert 0 == Bitmask.bit_at(0, 0)
    assert 1 == Bitmask.bit_at(1, 0)
    assert 0 == Bitmask.bit_at(1, 1)
    assert 1 == Bitmask.bit_at(8, 3)

    0..9
    |> Enum.each(fn n ->
      num = :math.pow(2, n) |> Float.floor() |> round()

      assert 1 == Bitmask.bit_at(num, n)
    end)
  end

  test "set_bit_at" do
    assert 0 == Bitmask.set_bit_at(1, 0, 0)
    assert 2 == Bitmask.set_bit_at(3, 0, 0)
    assert 12 == Bitmask.set_bit_at(14, 1, 0)
    assert 1 == Bitmask.set_bit_at(0, 0, 1)
    assert 2 == Bitmask.set_bit_at(0, 1, 1)
    assert 8 == Bitmask.set_bit_at(0, 3, 1)

    0..9
    |> Enum.each(fn n ->
      num = :math.pow(2, n) |> Float.floor() |> round()

      assert 0 == Bitmask.set_bit_at(num, n, 0)
    end)
  end

  test "hamming distance" do
    assert 0 == Bitmask.hamming_distance(0, 0)
    assert 0 == Bitmask.hamming_distance(1, 1)
    assert 0 == Bitmask.hamming_distance(1024, 1024)

    assert 1 == Bitmask.hamming_distance(0, 1)
    assert 1 == Bitmask.hamming_distance(1, 0)

    assert 2 == Bitmask.hamming_distance(1, 7)
    assert 2 == Bitmask.hamming_distance(1, 8)

    # Additional test cases
    # 111 vs 000
    assert 3 == Bitmask.hamming_distance(7, 0)
    # 1111 vs 0000
    assert 4 == Bitmask.hamming_distance(15, 0)
    # 11 vs 01
    assert 1 == Bitmask.hamming_distance(3, 1)
    # All bits different
    assert 32 == Bitmask.hamming_distance(0xFFFFFFFF, 0)
  end

  test "to_list" do
    assert [1] == Bitmask.to_list(1, 1)
    assert [0, 1] == Bitmask.to_list(1, 2)
    assert [1, 1, 0] == Bitmask.to_list(6, 3)
    assert [1, 0, 1, 0] == Bitmask.to_list(10, 4)
    assert [1, 0, 0, 0, 0] == Bitmask.to_list(16, 5)
  end

  describe "quirky edge cases" do
    test "set_bits_count with integer larger than 64 bits and negative integers" do
      # 1 shifted by 64 bits should logically have 1 bit set.
      # But due to the 64-bit masking implementation, it currently returns 0.
      assert Bitmask.set_bits_count(1 <<< 64) == 0

      # -1 in 2's complement is represented with all 1s (virtually infinite),
      # but set_bits_count is bounded by 64 bits so it returns 64.
      assert Bitmask.set_bits_count(-1) == 64
    end

    test "bit_at and set_bit_at with negative bit_index fail silently" do
      # Negative shifts yield 0, leading to silent no-ops rather than crashes.
      assert Bitmask.bit_at(10, -1) == 0
      assert Bitmask.set_bit_at(10, -1, 1) == 10
      assert Bitmask.set_bit_at(10, -1, 0) == 10
    end
    
    test "hamming_distance with integers larger than 64 bits" do
      # Since it uses set_bits_count, it also ignores bits above 64.
      assert Bitmask.hamming_distance(1 <<< 65, 0) == 0
    end
  end
end
