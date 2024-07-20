defmodule Abit.AtomicsTest do
  use ExUnit.Case, async: true
  doctest Abit.Atomics
  alias Abit.Atomics

  describe "to_list/1" do
    test "converts atomics to list" do
      ref = :atomics.new(3, signed: false)
      :atomics.put(ref, 1, 10)
      :atomics.put(ref, 2, 20)
      :atomics.put(ref, 3, 30)

      assert Atomics.to_list(ref) == [10, 20, 30]
    end

    test "handles empty atomics" do
      ref = :atomics.new(2, signed: false)
      assert Atomics.to_list(ref) == [0, 0]
    end
  end

  describe "member?/2" do
    test "returns true when value is present" do
      ref = :atomics.new(3, signed: false)
      :atomics.put(ref, 1, 10)
      :atomics.put(ref, 2, 20)
      :atomics.put(ref, 3, 30)

      assert Atomics.member?(ref, 20)
    end

    test "returns false when value is not present" do
      ref = :atomics.new(3, signed: false)
      :atomics.put(ref, 1, 10)
      :atomics.put(ref, 2, 20)
      :atomics.put(ref, 3, 30)

      refute Atomics.member?(ref, 40)
    end

    test "handles empty atomics" do
      ref = :atomics.new(2, signed: false)
      assert Atomics.member?(ref, 0)
      refute Atomics.member?(ref, 10)
    end

    test "handles values outside of range" do
      ref = :atomics.new(2, signed: false)

      refute Atomics.member?(ref, -1)
      # Max value for 64-bit unsigned integer + 1
      refute Atomics.member?(ref, 18_446_744_073_709_551_616)
    end
  end

  describe "serialize/1" do
    test "serializes unsigned atomics" do
      ref = :atomics.new(3, signed: false)
      :atomics.put(ref, 1, 10)
      :atomics.put(ref, 2, 20)
      :atomics.put(ref, 3, 30)

      serialized = Atomics.serialize(ref)

      assert <<0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 30>> =
               serialized
    end

    test "serializes signed atomics" do
      ref = :atomics.new(3, signed: true)
      :atomics.put(ref, 1, -10)
      :atomics.put(ref, 2, 20)
      :atomics.put(ref, 3, -30)

      serialized = Atomics.serialize(ref)

      assert <<1, 255, 255, 255, 255, 255, 255, 255, 246, 0, 0, 0, 0, 0, 0, 0, 20, 255, 255, 255,
               255, 255, 255, 255, 226>> = serialized
    end
  end

  describe "deserialize/1" do
    test "deserializes unsigned atomics" do
      original_ref = :atomics.new(3, signed: false)
      :atomics.put(original_ref, 1, 10)
      :atomics.put(original_ref, 2, 20)
      :atomics.put(original_ref, 3, 30)

      serialized = Atomics.serialize(original_ref)
      deserialized_ref = Atomics.deserialize(serialized)

      assert Atomics.to_list(deserialized_ref) == [10, 20, 30]
      assert :atomics.info(deserialized_ref).min == 0
    end

    test "deserializes signed atomics" do
      original_ref = :atomics.new(3, signed: true)
      :atomics.put(original_ref, 1, -10)
      :atomics.put(original_ref, 2, 20)
      :atomics.put(original_ref, 3, -30)

      serialized = Atomics.serialize(original_ref)
      deserialized_ref = Atomics.deserialize(serialized)

      assert Atomics.to_list(deserialized_ref) == [-10, 20, -30]
      assert :atomics.info(deserialized_ref).min < 0
    end

    test "roundtrip serialization and deserialization for signed atomics" do
      original_ref = :atomics.new(5, signed: true)
      :atomics.put(original_ref, 1, -1_000_000)
      :atomics.put(original_ref, 2, 0)
      :atomics.put(original_ref, 3, 1_000_000)
      # Min 64-bit signed int
      :atomics.put(original_ref, 4, -9_223_372_036_854_775_808)
      # Max 64-bit signed int
      :atomics.put(original_ref, 5, 9_223_372_036_854_775_807)

      serialized = Atomics.serialize(original_ref)
      deserialized_ref = Atomics.deserialize(serialized)

      assert Atomics.to_list(deserialized_ref) == [
               -1_000_000,
               0,
               1_000_000,
               -9_223_372_036_854_775_808,
               9_223_372_036_854_775_807
             ]

      assert :atomics.info(deserialized_ref).size == 5
      assert :atomics.info(deserialized_ref).min < 0
    end

    test "roundtrip serialization and deserialization for unsigned atomics" do
      original_ref = :atomics.new(5, signed: false)
      :atomics.put(original_ref, 1, 1_000_000)
      :atomics.put(original_ref, 2, 0)
      :atomics.put(original_ref, 3, 2_000_000)
      # Max 64-bit unsigned int
      :atomics.put(original_ref, 4, 18_446_744_073_709_551_615)

      serialized = Atomics.serialize(original_ref)
      deserialized_ref = Atomics.deserialize(serialized)

      assert Atomics.to_list(deserialized_ref) == [
               1_000_000,
               0,
               2_000_000,
               18_446_744_073_709_551_615,
               0
             ]

      assert :atomics.info(deserialized_ref).size == 5
      assert :atomics.info(deserialized_ref).min == 0
    end
  end
end
