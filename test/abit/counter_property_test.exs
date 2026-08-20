defmodule Abit.CounterPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Bitwise

  alias Abit.Counter

  @bit_sizes [2, 4, 8, 16, 32]

  property "valid values round trip for every counter representation" do
    check all({bit_size, signed, size, index, value} <- counter_value_case()) do
      counter = Counter.new(size, bit_size, signed: signed)

      assert {:ok, {^index, ^value}} = Counter.put(counter, index, value)
      assert Counter.get(counter, index) == value
    end
  end

  property "addition follows bounded and wrapping reference models" do
    check all({bit_size, signed, start, increment} <- addition_case()) do
      {min, max} = counter_range(signed, bit_size)
      next = start + increment

      bounded = Counter.new(1, bit_size, signed: signed)
      {:ok, {0, ^start}} = Counter.put(bounded, 0, start)

      if next in min..max do
        assert Counter.add(bounded, 0, increment) == {:ok, {0, next}}
        assert Counter.get(bounded, 0) == next
      else
        assert Counter.add(bounded, 0, increment) == {:error, :value_out_of_bounds}
        assert Counter.get(bounded, 0) == start
      end

      wrapping = Counter.new(1, bit_size, signed: signed, wrap_around: true)
      {:ok, {0, ^start}} = Counter.put(wrapping, 0, start)
      expected = min + Integer.mod(next - min, max - min + 1)

      assert Counter.add(wrapping, 0, increment) == {:ok, {0, expected}}
      assert Counter.get(wrapping, 0) == expected
    end
  end

  property "packing and unpacking preserves counter order and signedness" do
    check all({bit_size, signed, values} <- packed_values()) do
      counter = Counter.new(length(values), bit_size, signed: signed)

      values
      |> Enum.with_index()
      |> Enum.each(fn {value, index} ->
        assert {:ok, {^index, ^value}} = Counter.put(counter, index, value)
      end)

      assert Counter.get_all_at_atomic(counter, 1) == values
      assert Enum.to_list(counter) == values
    end
  end

  property "rejected writes leave the stored counter unchanged" do
    check all({bit_size, signed, valid, invalid} <- invalid_write_case()) do
      counter = Counter.new(1, bit_size, signed: signed)
      {:ok, {0, ^valid}} = Counter.put(counter, 0, valid)

      assert Counter.put(counter, 0, invalid) == {:error, :value_out_of_bounds}
      assert Counter.get(counter, 0) == valid
    end
  end

  defp counter_value_case do
    bind(counter_type(), fn {bit_size, signed, range} ->
      bind(integer(1..128), fn size ->
        tuple({
          constant(bit_size),
          constant(signed),
          constant(size),
          integer(0..(size - 1)),
          integer(range)
        })
      end)
    end)
  end

  defp addition_case do
    bind(counter_type(), fn {bit_size, signed, range} ->
      {min, max} = counter_range(signed, bit_size)
      span = max - min + 1

      tuple({
        constant(bit_size),
        constant(signed),
        integer(range),
        integer((-2 * span)..(2 * span))
      })
    end)
  end

  defp packed_values do
    bind(counter_type(), fn {bit_size, signed, range} ->
      count = div(64, bit_size)

      tuple({
        constant(bit_size),
        constant(signed),
        list_of(integer(range), length: count)
      })
    end)
  end

  defp invalid_write_case do
    bind(counter_type(), fn {bit_size, signed, range} ->
      {min, max} = counter_range(signed, bit_size)

      tuple({
        constant(bit_size),
        constant(signed),
        integer(range),
        one_of([integer((min - 1_000)..(min - 1)), integer((max + 1)..(max + 1_000))])
      })
    end)
  end

  defp counter_type do
    bind(member_of(@bit_sizes), fn bit_size ->
      bind(boolean(), fn signed ->
        {min, max} = counter_range(signed, bit_size)
        tuple({constant(bit_size), constant(signed), constant(min..max)})
      end)
    end)
  end

  defp counter_range(false, bit_size), do: {0, (1 <<< bit_size) - 1}

  defp counter_range(true, bit_size) do
    magnitude = 1 <<< (bit_size - 1)
    {-magnitude, magnitude - 1}
  end
end
