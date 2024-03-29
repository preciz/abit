defmodule Abit do
  @moduledoc """
  Use `:atomics` as a bit array or as an array of N-bit counters.

  [Erlang atomics documentation](http://erlang.org/doc/man/atomics.html)

  The `Abit` module (this module) has functions to use `:atomics` as a bit array.
  The bit array is zero indexed.

  The `Abit.Counter` module has functions to use `:atomics` as an array of N-bit
  counters.

  The `Abit.Bitmask` functions help working with bitmasks.

  ## Abit

      iex> ref = :atomics.new(100, signed: false)
      iex> Abit.bit_count(ref)
      6400
      iex> Abit.bit_at(ref, 0)
      0
      iex> Abit.set_bit_at(ref, 0, 1)
      :ok
      iex> Abit.bit_at(ref, 0)
      1

  ## Abit.Counter

      iex> counter = %Abit.Counter{} = Abit.Counter.new(100, 16)
      iex> Abit.Counter.get(counter, 0)
      0
      iex> Abit.Counter.put(counter, 0, 100)
      {:ok, {0, 100}}
      iex> Abit.Counter.add(counter, 0, 100)
      {:ok, {0, 200}}
      iex> Abit.Counter.member?(counter, 200)
      true

  ## Abit.Bitmask
      iex> Abit.Bitmask.set_bits_count(3)
      2
      iex> Abit.Bitmask.bit_at(2, 0)
      0
      iex> Abit.Bitmask.bit_at(2, 1)
      1
  """

  import Bitwise

  @doc """
  Returns total count of bits in atomics `ref`.

  `:atomics` are 64 bit integers so total
  count of bits is size * 64.

  ## Examples

      iex> ref = :atomics.new(1, signed: false)
      iex> Abit.bit_count(ref)
      64
      iex> ref2 = :atomics.new(2, signed: false)
      iex> Abit.bit_count(ref2)
      128
  """
  @spec bit_count(reference) :: pos_integer
  def bit_count(ref) when is_reference(ref) do
    :atomics.info(ref).size * 64
  end

  @doc """
  Merge bits of atomics `ref_a` & `ref_b` using the
  bitwise OR operator.

  `ref_b` will be merged into `ref_a`.
  Returns `ref_a` mutated.
  """
  @spec merge(reference, reference) :: reference
  def merge(ref_a, ref_b) when is_reference(ref_a) and is_reference(ref_b) do
    %{size: size} = ref_a |> :atomics.info()

    do_merge(ref_a, ref_b, size)
  end

  defp do_merge(ref_a, _, 0), do: ref_a

  defp do_merge(ref_a, ref_b, index) do
    merged_value = :atomics.get(ref_a, index) ||| :atomics.get(ref_b, index)

    :atomics.put(ref_a, index, merged_value)

    do_merge(ref_a, ref_b, index - 1)
  end

  @doc """
  Bit intersection of atomics using Bitwise AND operator.

  Returns `ref_a` mutated.
  """
  @spec intersect(reference, reference) :: reference
  def intersect(ref_a, ref_b) when is_reference(ref_a) and is_reference(ref_b) do
    %{size: size} = ref_a |> :atomics.info()

    do_intersect(ref_a, ref_b, size)
  end

  defp do_intersect(ref_a, _, 0), do: ref_a

  defp do_intersect(ref_a, ref_b, index) do
    intersected_value = :atomics.get(ref_a, index) &&& :atomics.get(ref_b, index)

    :atomics.put(ref_a, index, intersected_value)

    do_intersect(ref_a, ref_b, index - 1)
  end

  @doc """
  Sets the bit at `bit_index` to `bit` in the atomics `ref`.

  Returns `:ok`.

  ## Examples

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> Abit.set_bit_at(0, 1)
      iex> ref |> :atomics.get(1)
      1
      iex> ref |> Abit.set_bit_at(0, 0)
      :ok
      iex> ref |> :atomics.get(1)
      0
  """
  @spec set_bit_at(reference, non_neg_integer, 0 | 1) :: :ok
  def set_bit_at(ref, bit_index, bit) when is_reference(ref) and bit in [0, 1] do
    {atomics_index, integer_bit_index} = bit_position(bit_index)

    current_value = :atomics.get(ref, atomics_index)

    do_set_bit_at(ref, atomics_index, integer_bit_index, bit, current_value)
  end

  defp do_set_bit_at(ref, atomics_index, integer_bit_index, bit, current_value) do
    next_value = Abit.Bitmask.set_bit_at(current_value, integer_bit_index, bit)

    case :atomics.compare_exchange(ref, atomics_index, current_value, next_value) do
      :ok ->
        :ok

      non_matching_current_value ->
        do_set_bit_at(ref, atomics_index, integer_bit_index, bit, non_matching_current_value)
    end
  end

  @doc """
  Returns position of bit in `:atomics`.

  Returns a 2 tuple containing:
    * `atomics_index` - the index of the integer in atomics where the bit is located
    * `bit_index` - the index of the bit in the integer

  ## Examples

      iex> Abit.bit_position(0)
      {1, 0}
      iex> Abit.bit_position(11)
      {1, 11}
      iex> Abit.bit_position(64)
      {2, 0}
  """
  @spec bit_position(non_neg_integer) :: {non_neg_integer, non_neg_integer}
  def bit_position(bit_index) when is_integer(bit_index) and bit_index >= 0 do
    atomics_index = div(bit_index, 64) + 1

    bit_index = rem(bit_index, 64)

    {atomics_index, bit_index}
  end

  @doc """
  Returns bit at `bit_index` in atomic `ref`.

  ## Examples

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> :atomics.put(1, 3)
      iex> Abit.bit_at(ref, 0)
      1
      iex> Abit.bit_at(ref, 1)
      1
      iex> Abit.bit_at(ref, 2)
      0
  """
  @spec bit_at(reference, non_neg_integer) :: 0 | 1
  def bit_at(ref, bit_index) when is_reference(ref) and is_integer(bit_index) do
    {atomics_index, integer_bit_index} = bit_position(bit_index)

    bit_at(ref, atomics_index, integer_bit_index)
  end

  defp bit_at(ref, atomics_index, integer_bit_index) do
    integer = :atomics.get(ref, atomics_index)

    Abit.Bitmask.bit_at(integer, integer_bit_index)
  end

  @doc """
  Returns number of bits set to 1 in atomics array `ref`.

  ## Examples

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> :atomics.put(1, 3)
      iex> Abit.set_bits_count(ref)
      2
      iex> ref2 = :atomics.new(1, signed: false)
      iex> Abit.set_bits_count(ref2)
      0
  """
  @spec set_bits_count(reference) :: non_neg_integer
  def set_bits_count(ref) when is_reference(ref) do
    %{size: size} = ref |> :atomics.info()

    do_set_bits_count(ref, size, 0)
  end

  defp do_set_bits_count(_, 0, acc), do: acc

  defp do_set_bits_count(ref, index, acc) do
    set_bits_count_at_index = Abit.Bitmask.set_bits_count(:atomics.get(ref, index))

    do_set_bits_count(ref, index - 1, acc + set_bits_count_at_index)
  end

  @doc """
  Returns the bitwise hamming distance between the two
  given `:atomics` references `ref_l` and `ref_r`.

  Raises ArgumentError if the size of `ref_l` and `ref_r` don't equal.

  ## Examples

      iex> ref_l = :atomics.new(10, signed: false)
      iex> ref_r = :atomics.new(10, signed: false)
      iex> Abit.hamming_distance(ref_l, ref_r)
      0
      iex> ref_l |> :atomics.put(1, 7)
      iex> Abit.hamming_distance(ref_l, ref_r)
      3
  """
  @spec hamming_distance(reference, reference) :: non_neg_integer
  def hamming_distance(ref_l, ref_r) when is_reference(ref_l) and is_reference(ref_r) do
    %{size: ref_l_size} = :atomics.info(ref_l)
    %{size: ref_r_size} = :atomics.info(ref_r)

    if ref_l_size != ref_r_size do
      raise ArgumentError,
            "The sizes of the provided `:atomics` references don't match" <>
              "Size of `ref_l` is #{ref_l_size}. Size of `ref_r` is #{ref_r_size}."
    end

    do_hamming_distance(ref_l, ref_r, 1, ref_l_size, 0)
  end

  defp do_hamming_distance(ref_l, ref_r, index, index, acc) do
    acc + hamming_distance_at(ref_l, ref_r, index)
  end

  defp do_hamming_distance(ref_l, ref_r, index, size, acc) do
    do_hamming_distance(
      ref_l,
      ref_r,
      index + 1,
      size,
      acc + hamming_distance_at(ref_l, ref_r, index)
    )
  end

  defp hamming_distance_at(ref_l, ref_r, index) do
    ref_l_value = ref_l |> :atomics.get(index)
    ref_r_value = ref_r |> :atomics.get(index)

    Abit.Bitmask.hamming_distance(ref_l_value, ref_r_value)
  end

  @doc """
  Returns a flat list of every atomic value converted
  into a list of bits from `ref` atomics reference.

  ## Examples
      ref = :atomics.new(10, signed: false)
      ref |> Abit.to_list
      [0, 0, 0, 0, 0, ...]
  """
  @doc since: "0.2.3"
  @spec to_list(reference) :: list(0 | 1)
  def to_list(ref) when is_reference(ref) do
    size = :atomics.info(ref).size

    1..size
    |> Enum.flat_map(fn index ->
      :atomics.get(ref, index) |> Abit.Bitmask.to_list(64)
    end)
  end
end
