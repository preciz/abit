defmodule Abit do
  @moduledoc """
  Use :atomics as a bit array or as an array of counters with n bits per counter in Elixir.

  [Atomics](http://erlang.org/doc/man/atomics.html)

  The Abit module (this module) has functions to use an :atomics as a bit array.
  The Abit.Counter module has functions to create an array of counters and
  manipulate them.
  """

  import Bitwise

  @doc """
  Returns number of bits in atomics `ref`.

  Atomics are 64 bit integers so it is size * 64.

  ## Example

      iex> ref = :atomics.new(3, signed: false)
      iex> ref |> Abit.bit_count
      192
  """
  def bit_count(ref) when is_reference(ref) do
    %{size: size} = :atomics.info(ref)

    size * 64
  end

  @doc """
  Bit merge atomics using Bitwise OR operator.
  `ref_b` will be merged into `ref_a`.

  After the operation `ref_a` will be returned.
  """
  def merge(ref_a, ref_b) when is_reference(ref_a) and is_reference(ref_b) do
    %{size: size} = ref_a |> :atomics.info()

    merge(ref_a, ref_b, size)
  end

  defp merge(ref_a, _, 0), do: ref_a

  defp merge(ref_a, ref_b, index) do
    :atomics.put(
      ref_a,
      index,
      :atomics.get(ref_a, index) ||| :atomics.get(ref_b, index)
    )

    next_index = index - 1

    merge(ref_a, ref_b, next_index)
  end

  @doc """
  Bit intersection of atomics using Bitwise AND operator.

  After the operation `ref_a` will be returned.
  """
  def intersect(ref_a, ref_b) when is_reference(ref_a) and is_reference(ref_b) do
    %{size: size} = ref_a |> :atomics.info()

    intersect(ref_a, ref_b, size)
  end

  defp intersect(ref_a, _, 0), do: ref_a

  defp intersect(ref_a, ref_b, index) do
    :atomics.put(
      ref_a,
      index,
      :atomics.get(ref_a, index) &&& :atomics.get(ref_b, index)
    )

    next_index = index - 1

    intersect(ref_a, ref_b, next_index)
  end

  @doc """
  Sets the bit at `bit_index` to `bit` in the atomic `ref`.

  ## Example

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> :atomics.put(1, 1)
      iex> ref |> :atomics.get(1)
      1
      iex> ref |> Abit.set_bit(0, 0)
      :ok
      iex> ref |> :atomics.get(1)
      0
  """
  def set_bit(ref, bit_index, bit) when is_reference(ref) and bit in [0, 1] do
    {atomics_index, integer_bit_index} = bit_position(bit_index)

    case bit_at(ref, bit_index) do
      ^bit -> :ok
      _else ->
        set_bit(ref, atomics_index, integer_bit_index, bit, nil)
    end
  end

  defp set_bit(ref, atomics_index, integer_bit_index, bit, current_value) do
    current_value = current_value || :atomics.get(ref, atomics_index)

    next_value = Abit.Bitmask.set_bit_at(current_value, integer_bit_index, bit)

    case :atomics.compare_exchange(ref, atomics_index, current_value, next_value) do
      :ok ->
        :ok

      non_matching_current_value ->
        case Abit.Bitmask.bit_at(non_matching_current_value, integer_bit_index) do
          ^bit -> :ok
          _else -> set_bit(ref, atomics_index, integer_bit_index, bit, non_matching_current_value)
        end
    end
  end

  @doc """
  Returns a 2 tuple containing:

  `atomics_index` - the index of the atomics array where the bit is located
  `bit_index` - the index of the bit in the integer at `atomics_index`

  ## Example

      iex> Abit.bit_position(0)
      {1, 0}
      iex> Abit.bit_position(11)
      {1, 11}
      iex> Abit.bit_position(64)
      {2, 0}
  """
  def bit_position(bit_index) when is_integer(bit_index) and bit_index >= 0 do
    atomics_index = div(bit_index, 64) + 1

    bit_index = rem(bit_index, 64)

    {atomics_index, bit_index}
  end

  @doc """
  Returns bit at `bit_index` in atomic `ref`.

  ## Example

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> :atomics.put(1, 3)
      iex> Abit.bit_at(ref, 0)
      1
      iex> Abit.bit_at(ref, 1)
      1
      iex> Abit.bit_at(ref, 2)
      0
  """
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

  ## Example

      iex> ref = :atomics.new(1, signed: false)
      iex> ref |> :atomics.put(1, 3)
      iex> Abit.set_bits_count(ref)
      2
      iex> ref2 = :atomics.new(1, signed: false)
      iex> Abit.set_bits_count(ref2)
      0
  """
  def set_bits_count(ref) when is_reference(ref) do
    %{size: size} = ref |> :atomics.info()

    set_bits_count(ref, size, 0)
  end

  defp set_bits_count(_, 0, acc), do: acc

  defp set_bits_count(ref, index, acc) do
    count_at_index = Abit.Bitmask.set_bits_count(:atomics.get(ref, index))

    new_acc = acc + count_at_index

    next_index = index - 1

    set_bits_count(ref, next_index, new_acc)
  end
end
