defmodule Abit.Matrix do
  @moduledoc """
  Use `:atomics` as an M x N matrix.
  """
  @moduledoc since: "0.2.2"

  alias Abit.Matrix

  @enforce_keys [:atomics_ref, :m, :n]
  defstruct [:atomics_ref, :m, :n]

  @type t :: %__MODULE__{
          atomics_ref: reference,
          m: pos_integer,
          n: pos_integer
        }

  @type position :: {row :: non_neg_integer, col :: non_neg_integer}

  @doc """
  Returns a new `%Abit.Matrix{}` struct.

  ## Options
    * `:seed_fun` - a function that receives a 2-tuple `{row, col}`
  as argument and returns the initial value for the position
    * `:signed` - whether to have signed or unsigned 64bit integers

  ## Examples

       Abit.Matrix.new(10, 5) # 10 x 5 matrix
       Abit.Matrix.new(10, 5, signed: false) # unsigned integers
       Abit.Matrix.new(10, 5, seed_fun: fn {row, col} -> row * col end) # seed values
  """
  @spec new(pos_integer, pos_integer, list) :: t
  def new(m, n, options \\ []) when is_integer(m) and is_integer(n) do
    seed_fun = Keyword.get(options, :seed_fun, nil)
    signed = Keyword.get(options, :signed, true)

    atomics_ref = :atomics.new(m * n, signed: signed)

    matrix = %Matrix{atomics_ref: atomics_ref, m: m, n: n}

    if seed_fun do
      for index <- 1..(m * n) do
        position = index_to_position(matrix, index)

        value = seed_fun.(position)

        put(matrix, position, value)
      end
    end

    matrix
  end

  @doc """
  Returns a position tuple for the given atomics `index`.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10)
      iex> Abit.Matrix.index_to_position(matrix, 10)
      {0, 9}
  """
  @spec index_to_position(t, pos_integer) :: position
  def index_to_position(%Matrix{n: n}, index) when is_integer(index) do
    index = index - 1

    {div(index, n), rem(index, n)}
  end

  @doc """
  Returns atomics index corresponding to the `position`
  in the given `%Abit.Matrix{}` struct.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10)
      iex> matrix |> Abit.Matrix.position_to_index({1, 1})
      12
      iex> matrix |> Abit.Matrix.position_to_index({0, 4})
      5
  """
  @spec position_to_index(t, position) :: pos_integer
  def position_to_index(%Matrix{n: n}, {row, col}) do
    row * n + col + 1
  end

  @doc """
  Returns value at `position` from the given matrix.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10, seed_fun: fn _ -> 3 end)
      iex> matrix |> Abit.Matrix.get({0, 5})
      3
  """
  @spec get(t, position) :: integer
  def get(%Matrix{atomics_ref: atomics_ref} = matrix, position) do
    index = position_to_index(matrix, position)

    :atomics.get(atomics_ref, index)
  end

  @doc """
  Puts `value` into `matrix` at `position`.

  Returns `:ok`

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10)
      iex> matrix |> Abit.Matrix.put({1, 3}, 5)
      :ok
  """
  @spec put(t, position, integer) :: :ok
  def put(%Matrix{atomics_ref: atomics_ref} = matrix, position, value) when is_integer(value) do
    index = position_to_index(matrix, position)

    :atomics.put(atomics_ref, index, value)
  end

  @doc """
  Adds `incr` to value at `position` in matrix.

  Returns final value at `position`.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10)
      iex> matrix |> Abit.Matrix.add({0, 0}, 2)
      2
      iex> matrix |> Abit.Matrix.add({0, 0}, 2)
      4
      iex> matrix |> Abit.Matrix.add({0, 0}, -8)
      -4
  """
  @doc since: "0.2.3"
  @spec add(t, position, integer) :: integer
  def add(%Matrix{atomics_ref: atomics_ref} = matrix, position, incr) when is_integer(incr) do
    index = position_to_index(matrix, position)

    :atomics.add_get(atomics_ref, index, incr)
  end

  @doc """
  Returns size (rows * columns) of matrix.

  ## Examples

      iex> matrix = Abit.Matrix.new(5, 5)
      iex> matrix |> Abit.Matrix.size()
      25
  """
  @doc since: "0.2.3"
  @spec size(t) :: pos_integer
  def size(%Matrix{atomics_ref: atomics_ref}) do
    :atomics.info(atomics_ref).size
  end

  @doc """
  Returns row count of matrix.

  ## Examples

      iex> matrix = Abit.Matrix.new(4, 8)
      iex> matrix |> Abit.Matrix.rows()
      4
  """
  @doc since: "0.2.3"
  @spec rows(t) :: pos_integer
  def rows(%Matrix{m: m}), do: m

  @doc """
  Returns column count of matrix.

  ## Examples

      iex> matrix = Abit.Matrix.new(4, 8)
      iex> matrix |> Abit.Matrix.columns()
      8
  """
  @doc since: "0.2.3"
  @spec columns(t) :: pos_integer
  def columns(%Matrix{n: n}), do: n

  @doc """
  Returns smallest integer in `matrix`.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10, seed_fun: fn _ -> 7 end)
      iex> matrix |> Abit.Matrix.min()
      7
  """
  @doc since: "0.2.3"
  @spec min(t) :: integer
  def min(%Matrix{atomics_ref: atomics_ref} = matrix) do
    last_index = size(matrix)

    do_min(atomics_ref, last_index - 1, :atomics.get(atomics_ref, last_index))
  end

  defp do_min(_, 0, acc), do: acc

  defp do_min(atomics_ref, index, acc) do
    do_min(atomics_ref, index - 1, Kernel.min(acc, :atomics.get(atomics_ref, index)))
  end

  @doc """
  Returns largest integer in `matrix`.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10, seed_fun: fn {row, col} -> row * col end)
      iex> matrix |> Abit.Matrix.max()
      81
  """
  @doc since: "0.2.3"
  @spec max(t) :: integer
  def max(%Matrix{atomics_ref: atomics_ref} = matrix) do
    last_index = size(matrix)

    do_max(atomics_ref, last_index - 1, :atomics.get(atomics_ref, last_index))
  end

  defp do_max(_, 0, acc), do: acc

  defp do_max(atomics_ref, index, acc) do
    do_max(atomics_ref, index - 1, Kernel.max(acc, :atomics.get(atomics_ref, index)))
  end

  @doc """
  Returns sum of integers in `matrix`.

  ## Examples

      iex> matrix = Abit.Matrix.new(10, 10, seed_fun: fn {row, col} -> row * col end)
      iex> matrix |> Abit.Matrix.sum()
      2025
  """
  @doc since: "0.2.3"
  @spec sum(t) :: integer
  def sum(%Matrix{atomics_ref: atomics_ref} = matrix) do
    last_index = size(matrix)

    do_sum(atomics_ref, last_index - 1, :atomics.get(atomics_ref, last_index))
  end

  defp do_sum(_, 0, acc), do: acc

  defp do_sum(atomics_ref, index, acc) do
    do_sum(atomics_ref, index - 1, acc + :atomics.get(atomics_ref, index))
  end
end
