defmodule Abit.Atomics do
  @moduledoc """
  This module provides utility functions for working with Erlang's :atomics.
  """

  @unsigned_format 0
  @signed_format 1
  @bytes_per_value 8

  @doc """
  Converts an :atomics reference to a list of integers.

  This function takes an `:atomics` reference and returns a list containing
  the value of each element.

  ## Parameters

    * `atomics_ref` - A reference to an `:atomics` array.

  ## Returns

  A list of integers representing the values stored in the `:atomics` array.

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
  Checks whether an integer is present in the `:atomics` reference.

  This function checks whether the given integer matches any element in the
  provided `:atomics` reference.

  ## Parameters

    * `atomics_ref` - A reference to an `:atomics` array.
    * `int` - The integer to search for.

  ## Returns

  Returns `true` if the integer is found in the `:atomics` array, or `false` otherwise.

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
        do_member?(atomics_ref, int, size)
    end
  end

  defp do_member?(_, _, 0), do: false

  defp do_member?(atomics_ref, int, index) do
    :atomics.get(atomics_ref, index) == int or do_member?(atomics_ref, int, index - 1)
  end

  @doc """
  Serializes an `:atomics` reference into a binary.

  This function takes an `:atomics` reference and returns a binary in which each
  64-bit integer is encoded in big-endian format.

  ## Parameters

    * `atomics_ref` - A reference to an `:atomics` array.

  ## Returns

  A binary containing the serialized `:atomics` data.

  ## Examples

      iex> ref = :atomics.new(2, signed: false)
      iex> :atomics.put(ref, 1, 1)
      iex> :atomics.put(ref, 2, 2)
      iex> Abit.Atomics.serialize(ref)
      <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2>>

  """
  @doc since: "0.3.3"
  @spec serialize(reference()) :: binary()
  def serialize(atomics_ref) when is_reference(atomics_ref) do
    %{size: size} = :atomics.info(atomics_ref)

    signature_byte(atomics_ref) <> do_serialize(atomics_ref, 1, size, <<>>)
  end

  defp signature_byte(atomics_ref) when is_reference(atomics_ref) do
    case :atomics.info(atomics_ref) do
      %{min: 0} -> <<@unsigned_format>>
      %{min: n} when n < 0 -> <<@signed_format>>
    end
  end

  defp do_serialize(_atomics_ref, index, size, acc) when index > size, do: acc

  defp do_serialize(atomics_ref, index, size, acc) do
    value = :atomics.get(atomics_ref, index)
    do_serialize(atomics_ref, index + 1, size, acc <> <<value::64-big>>)
  end

  @doc """
  Deserializes a binary into an `:atomics` reference.

  This function takes a binary that was previously serialized using `serialize/1`
  and reconstructs an `:atomics` reference from it.

  The first byte is a format tag: `0` for unsigned values or `1` for signed
  values. It is followed by one or more big-endian 64-bit values. Other tags
  are reserved for future formats.

  Raises `ArgumentError` when the binary is empty, has an unknown format tag,
  contains no values, or has a payload that is not aligned to 64-bit values.

  ## Parameters

    * `binary` - A binary containing the serialized `:atomics` data.

  ## Returns

  A reference to a new `:atomics` array containing the deserialized data.

  ## Examples

      iex> ref = :atomics.new(2, [])
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, -20)
      iex> serialized = Abit.Atomics.serialize(ref)
      iex> deserialized_ref = Abit.Atomics.deserialize(serialized)
      iex> Abit.Atomics.to_list(deserialized_ref)
      [10, -20]

  """
  @doc since: "0.3.3"
  @spec deserialize(binary()) :: reference()
  def deserialize(<<>>) do
    raise ArgumentError, "serialized atomics binary cannot be empty"
  end

  def deserialize(<<format, payload::binary>>) do
    signed? = decode_format!(format)
    size = payload_size!(payload)

    atomics_ref = :atomics.new(size, signed: signed?)
    do_deserialize(signed?, atomics_ref, payload, 1)
    atomics_ref
  end

  defp decode_format!(@unsigned_format), do: false
  defp decode_format!(@signed_format), do: true

  defp decode_format!(format) do
    raise ArgumentError, "unknown atomics serialization format tag: #{format}"
  end

  defp payload_size!(<<>>) do
    raise ArgumentError, "serialized atomics payload must contain at least one 64-bit value"
  end

  defp payload_size!(payload) do
    byte_size = byte_size(payload)

    if rem(byte_size, @bytes_per_value) == 0 do
      div(byte_size, @bytes_per_value)
    else
      raise ArgumentError,
            "serialized atomics payload size must be a multiple of #{@bytes_per_value} bytes, " <>
              "got #{byte_size}"
    end
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
