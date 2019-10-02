defmodule Abit.Counter do
  @moduledoc """
  Use atomics as an array of counters with n bits per 64 bit integer.

  Possible counters:
  bits | unsigned value range | signed value range
  2      0..3                   -2..1
  4      0..15                  -8..7
  8      0..255                 -128..127
  16     0..65535               -32768..32767
  32     0..4294967295          -2147483648..2147483647

  If you need 64 bit counters:
  [Erlang -- counters](http://erlang.org/doc/man/counters.html)
  """

  @bit_sizes [2, 4, 8, 16, 32]

  alias Abit.Counter

  @keys [:atomics_ref, :signed, :size, :counters_bit_size, :min, :max]

  @enforce_keys @keys
  defstruct @keys

  def new(size, counters_bit_size, options \\ [])
      when is_integer(size) and is_integer(counters_bit_size) do
    import Bitwise

    if counters_bit_size not in @bit_sizes do
      raise ArgumentError,
            "You can't create an %Abit.Counter{} with counters_bit_size #{counters_bit_size}." <>
              "Possible values are #{inspect(@bit_sizes)}"
    end

    signed = options |> Keyword.get(:signed, true)

    atomics_size = ceil(size / (64 / counters_bit_size))

    atomics_ref = :atomics.new(atomics_size, signed: signed)

    {min, max} =
      case signed do
        false -> {0, (1 <<< counters_bit_size) - 1}
        true -> {-(1 <<< (counters_bit_size - 1)), (1 <<< (counters_bit_size - 1)) - 1}
      end

    %Counter{
      atomics_ref: atomics_ref,
      signed: signed,
      size: atomics_size * round(64 / counters_bit_size),
      counters_bit_size: counters_bit_size,
      min: min,
      max: max
    }
  end

  def get(
        %Counter{atomics_ref: atomics_ref, signed: signed, counters_bit_size: counters_bit_size},
        index
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    get_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>)
  end

  def put(
        %Counter{atomics_ref: atomics_ref, signed: signed, counters_bit_size: counters_bit_size},
        index,
        value
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    <<new_value::64>> =
      put_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>, value)

    :atomics.put(atomics_ref, atomics_index, new_value)
  end

  def add(
        counter = %Counter{
          atomics_ref: atomics_ref,
          signed: signed,
          counters_bit_size: counters_bit_size
        },
        index,
        incr
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    current_value = get_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>)

    next_value = current_value + incr

    <<next_atomics_value::64>> =
      put_value(signed, counters_bit_size, bit_index, <<atomics_value::64>>, next_value)

    case :atomics.compare_exchange(atomics_ref, atomics_index, atomics_value, next_atomics_value) do
      :ok ->
        :ok

      _other_value ->
        # there value at index was different, to keep the increment correct, we retry
        add(counter, index, incr)
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
             <<_left::unquote(left_bits), sign::1, value::unquote(counters_bit_size - 1),
               _right::unquote(right_bits)>>
           ) do
        case sign do
          0 -> value
          1 -> -value - 1
        end
      end

      defp unquote(:put_value)(
             false,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<left::unquote(left_bits), _current_value::unquote(counters_bit_size),
               right::unquote(right_bits)>>,
             new_value
           ) do
        <<left::unquote(left_bits), new_value::unquote(counters_bit_size),
          right::unquote(right_bits)>>
      end

      defp unquote(:put_value)(
             true,
             unquote(counters_bit_size),
             unquote(bit_index),
             <<left::unquote(left_bits), _sign::1, _current_value::unquote(counters_bit_size - 1),
               right::unquote(right_bits)>>,
             new_value
           ) do
        {new_value, sign} =
          case new_value < 0 do
            true -> {abs(new_value + 1), 1}
            false -> {new_value, 0}
          end

        <<left::unquote(left_bits), sign::1, new_value::unquote(counters_bit_size - 1),
          right::unquote(right_bits)>>
      end
    end)
  end)
end
