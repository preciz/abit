defmodule Abit.Bitmask do
  @moduledoc """
  Functions for working with bits & integer bitmasks.
  """

  import Bitwise

  @doc """
  Returns the count of bits set to 1 in `int` integer.

  ## Examples

      iex> Abit.Bitmask.set_bits_count(3)
      2
      iex> Abit.Bitmask.set_bits_count(0)
      0
      iex> Abit.Bitmask.set_bits_count(1024)
      1
      iex> Abit.Bitmask.set_bits_count(1023)
      10
  """
  @spec set_bits_count(integer) :: non_neg_integer
  def set_bits_count(int), do: set_bits_count(int, 0)

  defp set_bits_count(0, acc), do: acc

  defp set_bits_count(int, acc) when is_integer(int) and is_integer(acc) do
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

  @doc """
  Returns bit at `bit_index` in `ingteger`.

  ## Examples

      iex> Abit.Bitmask.bit_at(2, 0)
      0
      iex> Abit.Bitmask.bit_at(2, 1)
      1
      iex> Abit.Bitmask.bit_at(1, 0)
      1
      iex> Abit.Bitmask.bit_at(0, 0)
      0
  """
  @spec bit_at(integer, non_neg_integer) :: 0 | 1
  def bit_at(integer, bit_index) when is_integer(integer) and is_integer(bit_index) do
    case integer ||| 1 <<< bit_index do
      ^integer -> 1
      _else -> 0
    end
  end

  @doc """
  Sets the bit at `bit_index` in `integer` and
  returns `integer` with the bit set.

  ## Examples

      iex> Abit.Bitmask.set_bit_at(1, 0, 0)
      0
      iex> Abit.Bitmask.set_bit_at(0, 0, 1)
      1
      iex> Abit.Bitmask.set_bit_at(0, 2, 1)
      4
  """
  @spec set_bit_at(integer, non_neg_integer, 0 | 1) :: integer
  def set_bit_at(integer, bit_index, 0) do
    case bit_at(integer, bit_index) do
      0 -> integer
      1 -> integer ^^^ (1 <<< bit_index)
    end
  end

  def set_bit_at(integer, bit_index, 1) do
    integer ||| (1 <<< bit_index)
  end

  @doc """
  Returns the hamming distance of the bits of two integers.

  ## Examples

      iex> Abit.Bitmask.hamming_distance(1, 0)
      1
      iex> Abit.Bitmask.hamming_distance(1, 1023)
      9
      iex> Abit.Bitmask.hamming_distance(1, 1024)
      2
  """
  @spec hamming_distance(integer, integer) :: non_neg_integer
  def hamming_distance(int_l, int_r) when is_integer(int_l) and is_integer(int_r) do
    (int_l ^^^ int_r) |> set_bits_count
  end
end
