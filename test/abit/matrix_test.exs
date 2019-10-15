defmodule Abit.MatrixTest do
  use ExUnit.Case

  doctest Abit.Matrix

  alias Abit.Matrix

  test "new returns struct" do
    %Matrix{atomics_ref: atomics_ref, m: 50, n: 10} = Matrix.new(50, 10, signed: false)

    %{min: 0, size: 500} = :atomics.info(atomics_ref)

    %Matrix{atomics_ref: atomics_ref2, m: 2, n: 8} = Matrix.new(2, 8, signed: true)

    %{min: -9223372036854775808, size: 16} = :atomics.info(atomics_ref2)
  end

  test "seeds & gets values" do
    matrix = Matrix.new(10, 5, seed_fun: fn {row, col} -> row * col end)

    1..50
    |> Enum.each(fn index ->
      {row, col} = Matrix.index_to_position(matrix, index)

      assert row * col == Matrix.get(matrix, {row, col})
    end)
  end

  test "puts values" do
    matrix = Matrix.new(10, 10)

    20..40
    |> Enum.each(fn index ->
      {row, col} = Matrix.index_to_position(matrix, index)

      Matrix.put(matrix, {row, col}, index)

      assert index == Matrix.get(matrix, {row, col})
    end)
  end
end
