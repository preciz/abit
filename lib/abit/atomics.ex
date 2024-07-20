defmodule Abit.Atomics do
  @moduledoc """
  This module provides utility functions for working with Erlang's :atomics.
  """

  @doc """
  Converts an :atomics reference to a list of integers.

  This function takes an :atomics reference and returns a list of integers,
  where each integer represents the value stored in each atomic.

  ## Parameters

    * `atomics_ref` - A reference to an :atomics array.

  ## Returns

  A list of integers representing the values stored in the :atomics array.

  ## Examples

      iex> ref = :atomics.new(3, signed: false)
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, 20)
      iex> :atomics.put(ref, 3, 30)
      iex> Abit.Atomics.to_list(ref)
      [10, 20, 30]

  """
  @spec to_list(reference()) :: list(integer())
  def to_list(atomics_ref) when is_reference(atomics_ref) do
    do_to_list(atomics_ref, 1, :atomics.info(atomics_ref).size)
  end

  defp do_to_list(atomics_ref, size, size) do
    [:atomics.get(atomics_ref, size)]
  end

  defp do_to_list(atomics_ref, index, size) do
    [:atomics.get(atomics_ref, index) | do_to_list(atomics_ref, index + 1, size)]
  end

  @doc """
  Checks if an integer is present in the :atomics reference.

  This function checks if the given integer exists as a value in any of the
  atomics within the provided :atomics reference.

  ## Parameters

    * `atomics_ref` - A reference to an :atomics array.
    * `int` - The integer to search for.

  ## Returns

  Returns `true` if the integer is found in the :atomics array, `false` otherwise.

  ## Examples

      iex> ref = :atomics.new(3, signed: false)
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, 20)
      iex> :atomics.put(ref, 3, 30)
      iex> Abit.Atomics.member?(ref, 20)
      true
      iex> Abit.Atomics.member?(ref, 40)
      false

  """
  @spec member?(reference(), integer()) :: boolean()
  def member?(atomics_ref, int) when is_reference(atomics_ref) and is_integer(int) do
    %{min: min, max: max, size: size} = :atomics.info(atomics_ref)

    case int do
      i when i < min ->
        false

      i when i > max ->
        false

      _else ->
        do_member?(atomics_ref, int, size, false)
    end
  end

  defp do_member?(_, _, _, true), do: true

  defp do_member?(_, _, 0, false), do: false

  defp do_member?(atomics_ref, int, index, false) do
    do_member?(
      atomics_ref,
      int,
      index - 1,
      :atomics.get(atomics_ref, index) == int
    )
  end

  @doc """
  Serializes an :atomics reference into a binary.

  This function takes an :atomics reference and returns a binary where each
  64-bit integer in the :atomics array is encoded in big-endian format.

  ## Parameters

    * `atomics_ref` - A reference to an :atomics array.

  ## Returns

  A binary containing the serialized :atomics data.

  ## Examples

      iex> ref = :atomics.new(2, signed: false)
      iex> :atomics.put(ref, 1, 1)
      iex> :atomics.put(ref, 2, 2)
      iex> Abit.Atomics.serialize(ref)
      <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2>>

  """
  @spec serialize(reference()) :: binary()
  def serialize(atomics_ref) when is_reference(atomics_ref) do
    %{size: size} = :atomics.info(atomics_ref)

    signature_byte(atomics_ref) <> do_serialize(atomics_ref, 1, size, <<>>)
  end

  defp signature_byte(atomics_ref) when is_reference(atomics_ref) do
    case :atomics.info(atomics_ref) do
      %{min: 0} -> <<0>>
      %{min: n} when n < 0 -> <<1>>
    end
  end

  defp do_serialize(_atomics_ref, index, size, acc) when index > size, do: acc

  defp do_serialize(atomics_ref, index, size, acc) do
    value = :atomics.get(atomics_ref, index)
    do_serialize(atomics_ref, index + 1, size, acc <> <<value::64-big>>)
  end

  @doc """
  Deserializes a binary into an :atomics reference.

  This function takes a binary that was previously serialized using `serialize/1`
  and reconstructs an :atomics reference from it.

  ## Parameters

    * `binary` - A binary containing the serialized :atomics data.

  ## Returns

  A reference to a new :atomics array containing the deserialized data.

  ## Examples

      iex> ref = :atomics.new(2, [])
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, -20)
      iex> serialized = Abit.Atomics.serialize(ref)
      iex> deserialized_ref = Abit.Atomics.deserialize(serialized)
      iex> Abit.Atomics.to_list(deserialized_ref)
      [10, -20]

  """
  @spec deserialize(binary()) :: reference()
  def deserialize(<<signature_byte::8, rest::binary>>) do
    signed? =
      case signature_byte do
        0 -> false
        1 -> true
      end

    size = byte_size(rest) |> div(8)
    atomics_ref = :atomics.new(size, signed: signed?)
    do_deserialize(signed?, atomics_ref, rest, 1)
    atomics_ref
  end

  defp do_deserialize(_signed, _atomics_ref, <<>>, _index), do: :ok

  defp do_deserialize(false, atomics_ref, <<value::64-big, rest::binary>>, index) do
    :atomics.put(atomics_ref, index, value)
    do_deserialize(false, atomics_ref, rest, index + 1)
  end

  defp do_deserialize(true, atomics_ref, <<value::64-big-signed, rest::binary>>, index) do
    :atomics.put(atomics_ref, index, value)
    do_deserialize(true, atomics_ref, rest, index + 1)
  end
end
