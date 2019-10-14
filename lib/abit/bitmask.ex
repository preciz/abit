defmodule Abit.Bitmask do
  @moduledoc """
  Functions for working with bits & integer bitmasks.
  """

  import Bitwise

  @doc """
  Returns the count of bits set to 1 in the given integer `int`.

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
  def set_bits_count(int) when is_integer(int) do
    do_set_bits_count(int, 0)
  end

  defp do_set_bits_count(0, acc), do: acc

  defp do_set_bits_count(int, acc) do
    new_acc = acc + (int &&& 1)

    do_set_bits_count(int >>> 1, new_acc)
  end

  @doc """
  Returns bit at `bit_index` in the given `integer`.

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
  Sets the bit at `bit_index` in `integer` and returns it.

  ## Examples

      iex> Abit.Bitmask.set_bit_at(1, 0, 0)
      0
      iex> Abit.Bitmask.set_bit_at(0, 0, 1)
      1
      iex> Abit.Bitmask.set_bit_at(0, 2, 1)
      4
  """
  @spec set_bit_at(integer, non_neg_integer, 0 | 1) :: integer
  def set_bit_at2(integer, bit_index, 0) do
    integer &&& bnot(1 <<< bit_index)
  end

  def set_bit_at(integer, bit_index, 1) do
    integer ||| 1 <<< bit_index
  end

  @doc """
  Returns the bitwise hamming distance between the
  given integers `int_l` and `int_r`.

  ## Examples

      iex> Abit.Bitmask.hamming_distance(1, 1)
      0
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
