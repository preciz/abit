defmodule Abit.CounterTest do
  use ExUnit.Case, async: true

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

  test "gets & puts & adds value" do
    counter = Counter.new(10, 8)

    1..10
    |> Enum.each(fn index ->
      assert 0 = counter |> Counter.get(index)
    end)

    1..10
    |> Enum.each(fn n ->
      assert {:ok, {n, n}} = counter |> Counter.put(n, n)
      assert n = counter |> Counter.get(n)

      expected = n + n
      assert {:ok, {^n, ^expected}} = counter |> Counter.add(n, n)
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

  test "new/3 creates counters with correct size" do
    counter = Counter.new(100, 8)
    assert counter.size >= 100
    assert rem(counter.size, 8) == 0
  end

  test "new/3 raises error for invalid bit sizes" do
    assert_raise ArgumentError, fn ->
      Counter.new(10, 3)
    end
  end

  test "get/2 returns 0 for uninitialized counters" do
    counter = Counter.new(10, 8)
    assert 0 = Counter.get(counter, 5)
  end

  test "put/3 returns error for out-of-bounds values when wrap_around is false" do
    counter = Counter.new(10, 8)
    assert {:error, :value_out_of_bounds} = Counter.put(counter, 0, 256)
    assert {:error, :value_out_of_bounds} = Counter.put(counter, 0, -129)
  end

  test "add/3 wraps around correctly for signed counters" do
    counter = Counter.new(10, 8, wrap_around: true)
    Counter.put(counter, 0, 127)
    assert {:ok, {0, -128}} = Counter.add(counter, 0, 1)
    assert {:ok, {0, 127}} = Counter.add(counter, 0, 255)
  end

  test "member?/2 works correctly" do
    counter = Counter.new(100, 8)
    Counter.put(counter, 50, 42)
    assert Counter.member?(counter, 42)
    refute Counter.member?(counter, 43)
  end

  test "Enumerable protocol implementation" do
    counter = Counter.new(100, 8)
    Counter.put(counter, 50, 42)
    Counter.put(counter, 75, 100)

    assert Enum.count(counter) == 104
    assert Enum.member?(counter, 42)
    assert Enum.member?(counter, 100)
    refute Enum.member?(counter, 101)

    assert Enum.max(counter) == 100
  end
end
