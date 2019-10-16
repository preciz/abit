# Abit

Use `:atomics` as a bit array or as an array of N-bit counters.

Documentation can be found at [https://hexdocs.pm/abit](https://hexdocs.pm/abit).

## Installation

Add `abit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abit, "~> 0.2"}
  ]
end
```

## API summary
See [https://hexdocs.pm/abit](https://hexdocs.pm/abit) for full documentation.

### Abit - use `:atomics` as a bit array
* `Abit.bit_count/1` - Returns count of bits in atomics.
* `Abit.merge/2` - Merges bits of 2 atomics using Bitwise OR.
* `Abit.intersect/2` - Intersects bits of 2 atomics using Bitwise AND.
* `Abit.bit_position/1` - Returns the bit's position in an atomics array.
* `Abit.bit_at/2` - Returns the bit at a given position from atomics.
* `Abit.set_bit_at/3` - Sets the bit in atomics at the given position to the given bit (0 or 1).
* `Abit.set_bits_count/1` - Returns the number of bits set to 1 in atomics.
* `Abit.hamming_distance/2` - Returns the bitwise hamming distance between the 2 given atomics.
### Abit.Counter - use `:atomics` as an array of N-bit counters
* `Abit.Counter.new/2` - Create a new array of counters. Returns %Abit.Counter{} struct.
* `Abit.Counter.get/2` - Returns the value of counter at the given index.
* `Abit.Counter.put/3` - Puts the value into counter at the given index.
* `Abit.Counter.add/3` - Adds the increment to counter at the given index.
### Abit.Matrix - use `:atomics` as an M x N matrix
* `Abit.Matrix.new/2` - Create new matrix %Abit.Matrix{} struct.
* `Abit.Matrix.get/2` - Returns the integer at the given position.
* `Abit.Matrix.put/3` - Puts the given integer into the given position.
* `Abit.Matrix.add/3` - Adds the given integer into the given position atomically.
* `Abit.Matrix.exchange/3` - Exchanges the given integer at the given position atomically.
* `Abit.Matrix.compare_exchange/4` - Compares & exchanges the given integer at the given position atomically.
* `Abit.Matrix.index_to_position/2` - Converts the given atomics index to position tuple.
* `Abit.Matrix.position_to_index/2` - Converts the given position tuple to atomics index.
### Abit.Bitmask - helper functions for bitmasks
* `Abit.Bitmask.set_bits_count/1` - Returns the number of bits set to 1 in the given integer.
* `Abit.Bitmask.bit_at/2` - Returns the bit at a given position in the given integer.
* `Abit.Bitmask.set_bit_at/3` - Sets a bit in the given integer at the given position to a given bit (0 or 1).
* `Abit.hamming_distance/2` - Returns the bitwise hamming distance between the 2 given integers.
