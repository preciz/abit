defmodule Abit.BitmaskTest do
  use ExUnit.Case

  alias Abit.Bitmask
  doctest Bitmask

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

    0..9 |> Enum.each(fn n ->
      num = :math.pow(2, n) |> floor

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

    0..9 |> Enum.each(fn n ->
      num = :math.pow(2, n) |> floor

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
  end
end
