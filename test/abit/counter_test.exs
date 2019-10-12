defmodule Abit.CounterTest do
  use ExUnit.Case

  doctest Abit.Counter

  alias Abit.Counter

  test "creates new %Abit.Counter{} struct" do
    %Counter{
      atomics_ref: atomics_ref,
      signed: false,
      size: 80,
      counters_bit_size: 8,
      min: 0,
      max: 255
    } = Counter.new(80, 8, signed: false)

    assert is_reference(atomics_ref)

    %Counter{
      atomics_ref: atomics_ref,
      signed: true,
      size: size,
      counters_bit_size: 4,
      min: -8,
      max: 7
    } = Counter.new(100, 4)

    assert size >= 100 && size <= 120

    assert is_reference(atomics_ref)

    %Counter{
      atomics_ref: atomics_ref,
      signed: true,
      size: 10,
      counters_bit_size: 32,
      min: -2_147_483_648,
      max: 2_147_483_647
    } = Counter.new(10, 32)

    assert is_reference(atomics_ref)
  end

  test "gets & puts value" do
    counter = Counter.new(10, 8)

    1..10
    |> Enum.each(fn index ->
      assert 0 = counter |> Counter.get(index)
    end)

    1..10
    |> Enum.each(fn n ->
      assert {:ok, {n, n}} = counter |> Counter.put(n, n)
      assert n = counter |> Counter.get(n)
    end)
  end

  test "wrap_around: false" do
    counter = Counter.new(10, 8)

    counter |> Counter.put(0, 127)
    assert {:error, :value_out_of_bounds} = counter |> Counter.add(0, 1)

    counter |> Counter.put(1, -128)
    assert {:error, :value_out_of_bounds} = counter |> Counter.add(1, -1)
  end

  test "wrap_around: true" do
    counter = Counter.new(10, 8, wrap_around: true)

    counter |> Counter.put(0, 127)
    assert {:ok, {0, -128}} = counter |> Counter.add(0, 1)

    counter |> Counter.put(1, -128)
    assert {:ok, {1, 127}} = counter |> Counter.add(1, -1)
  end

  test "unsigned counters wrap around correctly" do
    counter = Counter.new(10, 8, signed: false, wrap_around: true)

    counter |> Counter.put(0, 255)
    assert {:ok, {0, 0}} = counter |> Counter.add(0, 1)

    counter2 = Counter.new(10, 4, signed: false, wrap_around: true)
    counter2 |> Counter.put(0, 15)
    assert {:ok, {0, 0}} = counter2 |> Counter.add(0, 1)
  end
end
