# Abit

Use :atomics as a bit array or as an array of counters with n bits per counter in Elixir.

Documentation can be found at [https://hexdocs.pm/abit](https://hexdocs.pm/abit).

## Installation

Add `abit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abit, "~> 0.1"}
  ]
end
```

## API

* `Abit.bit_count/1` - Returns count of bits in atomics.
* `Abit.merge/2` - Merges bits of 2 atomics using Bitwise OR.
* `Abit.intersect/2` - Intersects bits of 2 atomics using Bitwise AND.
* `Abit.set_bit/3` - Sets a bit in atomics at a given position to a given bit (0 or 1).
* `Abit.bit_position/1` - Returns the a bit's position in an atomics array.
* `Abit.bit_at/2` - Returns the bit at a given position from atomics.
* `Abit.set_bits_count/1` - Returns the number of bits set to 1 in atomics.

* `Abit.Counter.new/2` - Create a new array of counters. Returns %Abit.Counter{} struct.
* `Abit.Counter.get/2` - Returns the value of counter at the given index.
* `Abit.Counter.put/3` - Puts the value into counter at the given index.
* `Abit.Counter.add/3` - Adds the increment to counter at the given index.
