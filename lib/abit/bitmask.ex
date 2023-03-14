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
    case integer &&& 1 <<< bit_index do
      0 -> 0
      _else -> 1
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
  def set_bit_at(integer, bit_index, 0) do
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

  @doc """
  Converts the given `integer` to a list of bits.

  `size` is the size of the bitstring you want the integer to be
  converted to before creating a list from it.

  ## Examples

      iex> Abit.Bitmask.to_list(1, 1)
      [1]
      iex> Abit.Bitmask.to_list(1, 2)
      [0, 1]
      iex> Abit.Bitmask.to_list(214311324231232211111, 64)
      [1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1]
  """
  @doc since: "0.2.3"
  @spec to_list(integer, pos_integer) :: list(0 | 1)
  def to_list(integer, size) when is_integer(integer) and is_integer(size) and size > 0 do
    do_to_list(<<integer::size(size)>>)
  end

  defp do_to_list(<<bit::1, rest::bitstring>>) do
    [bit | do_to_list(rest)]
  end

  defp do_to_list(<<>>), do: []
end
