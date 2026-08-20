defmodule Abit.AtomicsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Bitwise

  alias Abit.Atomics
  alias Abit.Bitmask

  @min_signed_64 -(1 <<< 63)
  @max_signed_64 (1 <<< 63) - 1
  @max_unsigned_64 (1 <<< 64) - 1

  property "serialization round trips signed and unsigned atomics" do
    check all({signed, values} <- atomics_values()) do
      ref = atomics_from(values, signed)
      restored = ref |> Atomics.serialize() |> Atomics.deserialize()

      assert Atomics.to_list(restored) == values
      assert :atomics.info(restored).size == length(values)
      assert :atomics.info(restored).min < 0 == signed
      assert byte_size(Atomics.serialize(ref)) == 1 + 8 * length(values)
    end
  end

  property "unknown serialization format tags are rejected" do
    check all(format <- integer(2..255), payload <- binary(max_length: 32)) do
      assert_raise ArgumentError, "unknown atomics serialization format tag: #{format}", fn ->
        Atomics.deserialize(<<format, payload::binary>>)
      end
    end
  end

  property "misaligned serialization payloads are rejected" do
    check all(format <- member_of([0, 1]), payload <- misaligned_payload()) do
      assert_raise ArgumentError, ~r/payload size must be a multiple of 8 bytes/, fn ->
        Atomics.deserialize(<<format, payload::binary>>)
      end
    end
  end

  property "membership agrees with the source values" do
    check all({signed, values, candidate} <- membership_case()) do
      ref = atomics_from(values, signed)

      assert Atomics.member?(ref, candidate) == Enum.member?(values, candidate)
    end
  end

  property "binary bit-array operations match integer bitwise operations" do
    check all({left, right} <- equally_sized_unsigned_values()) do
      right_ref = atomics_from(right, false)

      assert left
             |> atomics_from(false)
             |> Abit.union(right_ref)
             |> Atomics.to_list() == zip_with(left, right, &bor/2)

      assert left
             |> atomics_from(false)
             |> Abit.intersect(right_ref)
             |> Atomics.to_list() == zip_with(left, right, &band/2)

      assert left
             |> atomics_from(false)
             |> Abit.difference(right_ref)
             |> Atomics.to_list() == zip_with(left, right, &band(&1, bnot(&2)))

      assert left
             |> atomics_from(false)
             |> Abit.symmetric_difference(right_ref)
             |> Atomics.to_list() == zip_with(left, right, &bxor/2)

      expected_distance =
        left
        |> Enum.zip(right)
        |> Enum.reduce(0, fn {left_value, right_value}, acc ->
          acc + Bitmask.set_bits_count(bxor(left_value, right_value))
        end)

      assert Abit.hamming_distance(atomics_from(left, false), right_ref) == expected_distance
    end
  end

  defp atomics_values do
    bind(boolean(), fn signed ->
      tuple(
        {constant(signed), list_of(integer(value_range(signed)), min_length: 1, max_length: 16)}
      )
    end)
  end

  defp membership_case do
    bind(atomics_values(), fn {signed, values} ->
      candidate = one_of([member_of(values), integer(value_range(signed))])
      tuple({constant(signed), constant(values), candidate})
    end)
  end

  defp misaligned_payload do
    bind(member_of([1, 2, 3, 4, 5, 6, 7, 9, 10, 15, 17, 31]), fn size ->
      binary(length: size)
    end)
  end

  defp equally_sized_unsigned_values do
    bind(integer(1..8), fn size ->
      values = list_of(integer(0..@max_unsigned_64), length: size)
      tuple({values, values})
    end)
  end

  defp value_range(true), do: @min_signed_64..@max_signed_64
  defp value_range(false), do: 0..@max_unsigned_64

  defp zip_with(left, right, fun) do
    left
    |> Enum.zip(right)
    |> Enum.map(fn {left_value, right_value} -> fun.(left_value, right_value) end)
  end

  defp atomics_from(values, signed) do
    ref = :atomics.new(length(values), signed: signed)

    values
    |> Enum.with_index(1)
    |> Enum.each(fn {value, index} -> :atomics.put(ref, index, value) end)

    ref
  end
end
