defmodule Abit.Counter do
  @moduledoc """
  Use `:atomics` as an array of counters with N bits per counter.
  An `:atomics` is an array of 64 bit integers so the possible counters are below:

  Possible counters:
      bits | unsigned value range | signed value range
      2    | 0..3                 | -2..1
      4    | 0..15                | -8..7
      8    | 0..255               | -128..127
      16   | 0..65535             | -32768..32767
      32   | 0..4294967295        | -2147483648..2147483647

  If you need 64 bit counters use:
  [Erlang counters](http://erlang.org/doc/man/counters.html)

  While Erlang :atomics are 1 indexed, `Abit.Counter` counters are 0 indexed.
  """

  @bit_sizes [2, 4, 8, 16, 32]

  alias Abit.Counter

  @keys [:atomics_ref, :signed, :wrap_around, :size, :counters_bit_size, :min, :max]

  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          atomics_ref: reference,
          signed: boolean,
          wrap_around: boolean,
          size: pos_integer,
          counters_bit_size: 2 | 4 | 8 | 16 | 32,
          min: integer,
          max: pos_integer
        }

  @doc """
  Returns a new `%Abit.Counter{}` struct.

    * `size` - minimum number of counters to have
      (if they don't fit exactly to 64 bit at the end, there will be a few more to fully fill the `:atomics`.
      check the `:size` key in the returned `%Abit.Counter{}` struct for the exact number of counters.)
    * `counters_bit_size` - how many bits a counter should use

  ## Options

    * `signed` - whether to have signed or unsigned counters. Defaults to `true`.
    * `wrap_around` - whether countesr should wrap around. Defaults to `false`.

  ## Examples

      Abit.Counter.new(100, 8) # minimum 100 counters; 8 bits signed
      Abit.Counter.new(10_000, 16, signed: false) # minimum 10_000 counters; 16 bits unsigned
      Abit.Counter.new(10_000, 16, wrap_around: false) # don't wrap around counters
  """
  @spec new(non_neg_integer, 2 | 4 | 8 | 16 | 32, list) :: t
  def new(size, counters_bit_size, options \\ [])
      when is_integer(size) and is_integer(counters_bit_size) do
    import Bitwise

    if counters_bit_size not in @bit_sizes do
      raise ArgumentError,
            "You can't create an %Abit.Counter{} with counters_bit_size #{counters_bit_size}." <>
              "Possible values are #{inspect(@bit_sizes)}"
    end

    signed = options |> Keyword.get(:signed, true)
    wrap_around = options |> Keyword.get(:wrap_around, false)

    atomics_size = ceil(size / (64 / counters_bit_size))

    atomics_ref = :atomics.new(atomics_size, signed: false)

    {min, max} =
      case signed do
        false -> {0, (1 <<< counters_bit_size) - 1}
        true -> {-(1 <<< (counters_bit_size - 1)), (1 <<< (counters_bit_size - 1)) - 1}
      end

    %Counter{
      atomics_ref: atomics_ref,
      signed: signed,
      wrap_around: wrap_around,
      size: atomics_size * round(64 / counters_bit_size),
      counters_bit_size: counters_bit_size,
      min: min,
      max: max
    }
  end

  @doc """
  Returns the value of counter at `index`.

  ## Examples

      iex> c = Abit.Counter.new(10, 8)
      iex> c |> Abit.Counter.get(7)
      0
  """
  @spec get(t, non_neg_integer) :: integer
  def get(
        %Counter{atomics_ref: atomics_ref, signed: signed, counters_bit_size: counters_bit_size},
        index
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    get_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>)
  end

  @doc """
  Puts the value into the counter at `index`.

  Returns `{:ok, value}` or `{:error, :value_out_of_bounds}` if
  option `wrap_around` is `false` and value is out of bounds.

  ## Examples

      iex> c = Abit.Counter.new(10, 8)
      iex> c |> Abit.Counter.put(7, -12)
      {:ok, {7, -12}}
      iex> c |> Abit.Counter.get(7)
      -12
  """
  @spec put(t, non_neg_integer, integer) :: :ok
  def put(%Counter{wrap_around: false, min: min, max: max}, _, value)
      when value < min or value > max do
    {:error, :value_out_of_bounds}
  end

  def put(
        %Counter{atomics_ref: atomics_ref, signed: signed, counters_bit_size: counters_bit_size},
        index,
        value
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    {final_counter_value, <<next_atomics_value::64>>} =
      put_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>, value)

    :atomics.put(atomics_ref, atomics_index, next_atomics_value)

    {:ok, {index, final_counter_value}}
  end

  @doc """
  Increments the value of the counter at `index` with `incr`.

  Returns `{:ok, value_after_increment}` or `{:error, :value_out_of_bounds}` if
  option `wrap_around` is `false` and value is out of bounds.

  ## Examples

      iex> c = Abit.Counter.new(10, 8)
      iex> c |> Abit.Counter.add(7, -12)
      iex> c |> Abit.Counter.add(7, -12)
      {:ok, {7, -24}}
      iex> c |> Abit.Counter.get(7)
      -24
  """
  @spec add(t, non_neg_integer, integer) :: :ok
  def add(
        counter = %Counter{
          atomics_ref: atomics_ref,
          signed: signed,
          wrap_around: wrap_around,
          counters_bit_size: counters_bit_size,
          min: min,
          max: max
        },
        index,
        incr
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    current_value = get_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>)

    next_value = current_value + incr

    case {wrap_around, next_value < min or next_value > max} do
      {false, true} ->
        {:error, :value_out_of_bounds}

      {_, _} ->
        {final_counter_value, <<next_atomics_value::64>>} =
          put_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>, next_value)

        case :atomics.compare_exchange(
               atomics_ref,
               atomics_index,
               atomics_value,
               next_atomics_value
             ) do
          :ok ->
            {:ok, {index, final_counter_value}}

          _other_value ->
            # The value at index was different. To keep the increment correct we retry.
            add(counter, index, incr)
        end
    end
  end

  @bit_sizes
  |> Enum.each(fn counters_bit_size ->
    0..63
    |> Enum.filter(fn n -> rem(n, counters_bit_size) == 0 end)
    |> Enum.each(fn bit_index ->
      bit_left_start = bit_index + counters_bit_size
      left_bits = 64 - bit_left_start
      right_bits = bit_left_start - counters_bit_size

      defp unquote(:get_value)(
             false,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<_::unquote(left_bits), value::unquote(counters_bit_size), _::unquote(right_bits)>>
           ) do
        value
      end

      defp unquote(:get_value)(
             true,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<_left::unquote(left_bits), value::unquote(counters_bit_size)-signed,
               _right::unquote(right_bits)>>
           ) do
        value
      end

      defp unquote(:put_value)(
             false,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<left::unquote(left_bits), _current_value::unquote(counters_bit_size),
               right::unquote(right_bits)>>,
             new_value
           ) do
        <<final_counter_value::unquote(counters_bit_size)>> =
          <<new_value::unquote(counters_bit_size)>>

        {
          final_counter_value,
          <<left::unquote(left_bits), new_value::unquote(counters_bit_size),
            right::unquote(right_bits)>>
        }
      end

      defp unquote(:put_value)(
             true,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<left::unquote(left_bits), _current_value::unquote(counters_bit_size)-signed,
               right::unquote(right_bits)>>,
             new_value
           ) do
        <<final_counter_value::unquote(counters_bit_size)-signed>> =
          <<new_value::unquote(counters_bit_size)-signed>>

        {
          final_counter_value,
          <<left::unquote(left_bits), new_value::unquote(counters_bit_size)-signed,
            right::unquote(right_bits)>>
        }
      end
    end)
  end)
end
