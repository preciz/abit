defmodule Abit.BitmaskPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Bitwise

  alias Abit.Bitmask

  @min_signed_64 -(1 <<< 63)
  @max_unsigned_64 (1 <<< 64) - 1

  property "64-bit list conversion and population count agree" do
    check all(integer <- integer(@min_signed_64..@max_unsigned_64)) do
      bits = Bitmask.to_list(integer, 64)

      assert length(bits) == 64
      assert Bitmask.set_bits_count(integer) == Enum.sum(bits)

      bits
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.each(fn {bit, index} ->
        assert Bitmask.bit_at(integer, index) == bit
      end)
    end
  end

  property "setting and toggling one bit preserve every other bit" do
    check all(
            integer <- integer(@min_signed_64..@max_unsigned_64),
            index <- integer(0..63),
            bit <- member_of([0, 1])
          ) do
      updated = Bitmask.set_bit_at(integer, index, bit)

      assert Bitmask.bit_at(updated, index) == bit
      assert Bitmask.set_bit_at(updated, index, bit) == updated

      changed_bits = Bitmask.hamming_distance(integer, updated)
      assert changed_bits in [0, 1]

      toggled = Bitmask.toggle_bit_at(integer, index)
      assert Bitmask.bit_at(toggled, index) == 1 - Bitmask.bit_at(integer, index)
      assert Bitmask.toggle_bit_at(toggled, index) == integer
    end
  end

  property "Hamming distance is symmetric and matches XOR population count" do
    check all(
            left <- integer(@min_signed_64..@max_unsigned_64),
            right <- integer(@min_signed_64..@max_unsigned_64)
          ) do
      distance = Bitmask.hamming_distance(left, right)

      assert distance == Bitmask.hamming_distance(right, left)
      assert distance == Bitmask.set_bits_count(bxor(left, right))
      assert distance in 0..64
    end
  end
end
