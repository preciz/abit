defmodule Abit.AtomicsTest do
  use ExUnit.Case, async: true
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
end
