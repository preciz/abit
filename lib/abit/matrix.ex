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
  Puts value into `matrix` at `position`.

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
end
