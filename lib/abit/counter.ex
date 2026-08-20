defmodule Abit.Counter do
  @moduledoc """
  Uses `:atomics` as an array of counters with N bits per counter.
  An `:atomics` reference stores an array of 64-bit integers.

  Supported counter widths and value ranges:
      bits | unsigned value range | signed value range
      2    | 0..3                 | -2..1
      4    | 0..15                | -8..7
      8    | 0..255               | -128..127
      16   | 0..65535             | -32768..32767
      32   | 0..4294967295        | -2147483648..2147483647

  If you need 64-bit counters, use
  [Erlang counters](http://erlang.org/doc/man/counters.html)

  The `:wrap_around` option defaults to `false`, which is a safe default for
  these small counters. When `:wrap_around` is `false` and an operation would
  produce an out-of-bounds value, `put/3` and `add/3` return
  `{:error, :value_out_of_bounds}` without changing the stored value.

  While Erlang `:atomics` elements are 1-indexed, `Abit.Counter` counters are
  0-indexed.

  ## Enumerable protocol

  `Abit.Counter` implements the Enumerable protocol, so all Enum functions can be used:

      iex> c = Abit.Counter.new(1000, 16, signed: false)
      iex> c |> Abit.Counter.put(700, 54321)
      iex> c |> Enum.max()
      54321

  ## Examples

      iex> c = Abit.Counter.new(1000, 8, signed: false)
      iex> c |> Abit.Counter.put(0, 100)
      {:ok, {0, 100}}
      iex> c |> Abit.Counter.add(0, 100)
      {:ok, {0, 200}}
      iex> c |> Abit.Counter.add(0, 100)
      {:error, :value_out_of_bounds}

  """

  @bit_sizes [2, 4, 8, 16, 32]

  import Bitwise

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

    * `size` - the minimum number of counters. Counters fully fill the `:atomics`
      array, so check the `:size` key in the returned `%Abit.Counter{}` for the exact count.
    * `counters_bit_size` - how many bits a counter should use

  ## Options

    * `:signed` - whether to have signed or unsigned counters. Defaults to `true`.
    * `:wrap_around` - whether counters should wrap around. Defaults to `false`.

  ## Examples

      Abit.Counter.new(100, 8) # minimum 100 counters; 8 bits signed
      Abit.Counter.new(10_000, 16, signed: false) # minimum 10_000 counters; 16 bits unsigned
      Abit.Counter.new(10_000, 16, wrap_around: false) # don't wrap around
  """
  @spec new(non_neg_integer(), 2 | 4 | 8 | 16 | 32, keyword()) :: t()
  def new(size, counters_bit_size, options \\ [])
      when is_integer(size) and is_integer(counters_bit_size) do
    if counters_bit_size not in @bit_sizes do
      raise ArgumentError,
            "You can't create a %Abit.Counter{} with counters_bit_size #{counters_bit_size}. " <>
              "Possible values are #{inspect(@bit_sizes)}"
    end

    signed = options |> Keyword.get(:signed, true)
    wrap_around = options |> Keyword.get(:wrap_around, false)

    atomics_size = Float.ceil(size / (64 / counters_bit_size)) |> round()

    atomics_ref = :atomics.new(atomics_size, signed: false)

    {min, max} = counter_range(signed, counters_bit_size)

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
  Returns the value of the counter at `index`.

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

    get_value(signed, counters_bit_size, bit_index, atomics_value)
  end

  @doc """
  Puts the value into the counter at `index`.

  Returns `{:ok, {index, final_value}}`, or `{:error, :value_out_of_bounds}` if
  `wrap_around` is `false` and the value is out of bounds.

  ## Examples

      iex> c = Abit.Counter.new(10, 8)
      iex> c |> Abit.Counter.put(7, -12)
      {:ok, {7, -12}}
      iex> c |> Abit.Counter.get(7)
      -12
      iex> c |> Abit.Counter.put(7, 128)
      {:error, :value_out_of_bounds}
  """
  @spec put(t, non_neg_integer, integer) ::
          {:ok, {non_neg_integer, integer}} | {:error, :value_out_of_bounds}
  def put(%Counter{wrap_around: false, min: min, max: max}, _, value)
      when value < min or value > max do
    {:error, :value_out_of_bounds}
  end

  def put(
        %Counter{atomics_ref: atomics_ref, counters_bit_size: counters_bit_size} = counter,
        index,
        value
      )
      when index >= 0 do
    {atomics_index, bit_index} = Abit.bit_position(counters_bit_size * index)

    atomics_value = :atomics.get(atomics_ref, atomics_index)

    do_put(counter, index, value, atomics_index, bit_index, atomics_value)
  end

  defp do_put(
         %Counter{
           atomics_ref: atomics_ref,
           signed: signed,
           counters_bit_size: counters_bit_size
         } = counter,
         index,
         value,
         atomics_index,
         bit_index,
         atomics_value
       ) do
    {final_counter_value, next_atomics_value} =
      put_value(signed, counters_bit_size, bit_index, atomics_value, value)

    case :atomics.compare_exchange(
           atomics_ref,
           atomics_index,
           atomics_value,
           next_atomics_value
         ) do
      :ok ->
        {:ok, {index, final_counter_value}}

      new_atomics_value ->
        do_put(counter, index, value, atomics_index, bit_index, new_atomics_value)
    end
  end

  @doc """
  Increments the value of the counter at `index` by `incr`.

  Returns `{:ok, {index, final_value}}`, or `{:error, :value_out_of_bounds}` if
  `wrap_around` is `false` and the value is out of bounds.

  ## Examples

      iex> c = Abit.Counter.new(10, 8)
      iex> c |> Abit.Counter.add(7, -12)
      {:ok, {7, -12}}
      iex> c |> Abit.Counter.add(7, 36)
      {:ok, {7, 24}}
      iex> c |> Abit.Counter.put(1, 1000)
      {:error, :value_out_of_bounds}
  """
  @spec add(t, non_neg_integer, integer) ::
          {:ok, {non_neg_integer, integer}} | {:error, :value_out_of_bounds}
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

    current_value = get_value(signed, counters_bit_size, bit_index, atomics_value)

    next_value = current_value + incr

    case {wrap_around, next_value < min or next_value > max} do
      {false, true} ->
        {:error, :value_out_of_bounds}

      {_, _} ->
        {final_counter_value, next_atomics_value} =
          put_value(signed, counters_bit_size, bit_index, atomics_value, next_value)

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

  @doc """
  Returns `true` if any counter has the value `integer`,
  `false` otherwise.

  ## Examples

      iex> c = Abit.Counter.new(100, 8)
      iex> c |> Abit.Counter.member?(0)
      true
      iex> c |> Abit.Counter.member?(80)
      false
  """
  @doc since: "0.2.4"
  @spec member?(t, integer) :: boolean
  def member?(
        %Counter{
          atomics_ref: atomics_ref,
          min: min,
          max: max
        } = counter,
        int
      )
      when is_integer(int) do
    case int do
      i when i < min ->
        false

      i when i > max ->
        false

      _else ->
        do_member?(counter, int, 1, :atomics.info(atomics_ref).size)
    end
  end

  defp do_member?(counter, int, index, index) do
    int in get_all_at_atomic(counter, index)
  end

  defp do_member?(counter, int, index, atomics_size) do
    case int in get_all_at_atomic(counter, index) do
      true -> true
      false -> do_member?(counter, int, index + 1, atomics_size)
    end
  end

  @doc """
  Sets all elements in the given `counter` array to 0.

  Returns `counter`.

  ## Examples

      iex> c = Abit.Counter.new(100, 8)
      iex> c |> Abit.Counter.put(3, 70)
      iex> c |> Abit.Counter.clear()
      iex> c |> Abit.Counter.get(3)
      0
  """
  @doc since: "0.4.0"
  @spec clear(t) :: t
  def clear(%Counter{atomics_ref: atomics_ref} = counter) do
    Abit.clear(atomics_ref)
    counter
  end

  @doc """
  Returns all counters packed into the atomics element at `index`.

  Indices in `:atomics` are one-based.

  ## Examples

      iex> c = Abit.Counter.new(100, 8)
      iex> c |> Abit.Counter.put(3, -70)
      iex> c |> Abit.Counter.get_all_at_atomic(1)
      [0, 0, 0, -70, 0, 0, 0, 0]

  """
  @doc since: "0.2.4"
  @spec get_all_at_atomic(t, pos_integer) :: list(integer)
  def get_all_at_atomic(
        %Counter{atomics_ref: atomics_ref, signed: signed, counters_bit_size: bit_size},
        atomic_index
      )
      when is_integer(atomic_index) do
    atomic = :atomics.get(atomics_ref, atomic_index)

    integer_to_counters(atomic, signed, bit_size)
  end

  defimpl Enumerable do
    @moduledoc false
    @moduledoc since: "0.2.4"

    alias Abit.Counter

    def count(%Counter{size: size}) do
      {:ok, size}
    end

    def member?(%Counter{} = counter, int) when is_integer(int) do
      {:ok, Counter.member?(counter, int)}
    end

    if Version.match?(System.version(), ">= 1.12.0-dev") do
      def slice(%Counter{size: size} = counter) do
        {:ok, size, fn start, length, step -> do_slice(counter, start, length, step) end}
      end
    else
      def slice(%Counter{size: size} = counter) do
        {:ok, size, fn start, length -> do_slice(counter, start, length, 1) end}
      end
    end

    defp do_slice(_, _, 0, _), do: []

    defp do_slice(counter, index, length, step) do
      [counter |> Counter.get(index) | do_slice(counter, index + step, length - 1, step)]
    end

    def reduce(%Counter{atomics_ref: atomics_ref} = counter, acc, fun) do
      size = :atomics.info(atomics_ref).size

      do_reduce({counter, [], 0, size}, acc, fun)
    end

    def do_reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
    def do_reduce(tuple, {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(tuple, &1, fun)}
    def do_reduce({_, [], size, size}, {:cont, acc}, _fun), do: {:done, acc}

    def do_reduce({counter, [h | tl], index, size}, {:cont, acc}, fun) do
      do_reduce(
        {counter, tl, index, size},
        fun.(h, acc),
        fun
      )
    end

    def do_reduce({counter, [], index, size}, {:cont, acc}, fun) do
      [h | tl] = Counter.get_all_at_atomic(counter, index + 1)

      do_reduce(
        {counter, tl, index + 1, size},
        fun.(h, acc),
        fun
      )
    end
  end

  defp get_value(signed, bit_size, bit_index, atomic) do
    value = atomic >>> bit_index &&& bit_mask(bit_size)
    decode_value(value, signed, bit_size)
  end

  defp put_value(signed, bit_size, bit_index, atomic, new_value) do
    mask = bit_mask(bit_size)
    encoded_value = new_value &&& mask
    shifted_mask = mask <<< bit_index
    next_atomic = (atomic &&& bnot(shifted_mask)) ||| encoded_value <<< bit_index

    {decode_value(encoded_value, signed, bit_size), next_atomic}
  end

  defp decode_value(value, false, _bit_size), do: value

  defp decode_value(value, true, bit_size) do
    sign_bit = 1 <<< (bit_size - 1)
    if (value &&& sign_bit) == 0, do: value, else: value - (sign_bit <<< 1)
  end

  for bit_size <- @bit_sizes do
    defp bit_mask(unquote(bit_size)), do: unquote((1 <<< bit_size) - 1)
  end

  defp integer_to_counters(integer, signed, bit_size) do
    do_integer_to_counters(<<integer::64>>, signed, bit_size, [])
  end

  for bit_size <- @bit_sizes do
    defp do_integer_to_counters(
           <<int::unquote(bit_size), rest::bitstring>>,
           false,
           unquote(bit_size),
           acc
         ) do
      do_integer_to_counters(rest, false, unquote(bit_size), [int | acc])
    end

    defp do_integer_to_counters(
           <<int::unquote(bit_size)-signed, rest::bitstring>>,
           true,
           unquote(bit_size),
           acc
         ) do
      do_integer_to_counters(rest, true, unquote(bit_size), [int | acc])
    end

    defp do_integer_to_counters(<<>>, _, _, acc), do: acc
  end

  # Returns the {min, max} counter range for the given signed flag and bit size.
  defp counter_range(signed, bit_size) do
    case signed do
      false -> {0, (1 <<< bit_size) - 1}
      true -> {-(1 <<< (bit_size - 1)), (1 <<< (bit_size - 1)) - 1}
    end
  end
end
