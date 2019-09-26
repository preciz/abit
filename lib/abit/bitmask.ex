defmodule Abit.Bitmask do
  @moduledoc false
  # Helper functions for working with bitmasks.

  import Bitwise

  def set_bits_count(int, acc \\ 0)

  def set_bits_count(0, acc), do: acc

  def set_bits_count(int, acc) when is_integer(int) and is_integer(acc) do
    case int &&& 1 do
      0 ->
        int = int >>> 1

        set_bits_count(int, acc)

      1 ->
        int = int >>> 1

        new_acc = acc + 1

        set_bits_count(int, new_acc)
    end
  end

  def bit_at(integer, bit_index) when is_integer(integer) and is_integer(bit_index) do
    case integer ||| 1 <<< bit_index do
      ^integer -> 1
      _else -> 0
    end
  end

  def set_bit_at(integer, bit_index, bit) do
    case bit_at(integer, bit_index) do
      ^bit -> integer
      0 -> integer ||| (1 <<< bit_index)
      1 -> integer ^^^ (1 <<< bit_index)
    end
  end
end
