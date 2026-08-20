# Abit

[![test](https://github.com/preciz/abit/actions/workflows/test.yml/badge.svg)](https://github.com/preciz/abit/actions/workflows/test.yml)

Use Erlang's `:atomics` as a mutable bit array or as an array of packed N-bit counters.

See the [API documentation](https://hexdocs.pm/abit) on HexDocs.

## Installation

Abit requires Elixir 1.7 or later and OTP 21.2.1 or later.

Add `abit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abit, "~> 0.4"}
  ]
end
```

## API summary

Abit indexes bits and packed counters from zero. Raw `:atomics` indexes, including
the index accepted by `Abit.Counter.get_all_at_atomic/2`, start from one.

Operations that write to an `:atomics` reference mutate it in place. See the
[full API documentation](https://hexdocs.pm/abit) for examples and return values.

### Abit - use `:atomics` as a bit array
* `Abit.bit_count/1` - Returns the total number of bits in an atomics reference.
* `Abit.union/2` - Combines two atomics references using bitwise OR.
* `Abit.intersect/2` - Intersects two atomics references using bitwise AND.
* `Abit.difference/2` - Clears bits in the left-hand atomics reference that are set in the right-hand reference using bitwise AND NOT.
* `Abit.symmetric_difference/2` - Computes the symmetric difference of two atomics references using bitwise XOR.
* `Abit.invert/1` - Inverts all bits in a signed atomics reference using bitwise NOT.
* `Abit.bit_position/1` - Returns a bit's position in an atomics array.
* `Abit.bit_at/2` - Returns the bit at a given position in an atomics reference.
* `Abit.set_bit_at/3` - Sets the bit at a given position in an atomics reference to 0 or 1.
* `Abit.toggle_bit_at/2` - Toggles the bit at a given position in an atomics reference.
* `Abit.clear/1` - Sets all elements in the atomics reference to 0.
* `Abit.set_bits_count/1` - Returns the number of bits set to 1 in an atomics reference.
* `Abit.hamming_distance/2` - Returns the bitwise Hamming distance between two atomics references.
* `Abit.to_list/1` - Converts every integer in an atomics reference into a flat list of bits.

### Abit.Atomics - utility functions for working with Erlang's `:atomics`
* `Abit.Atomics.to_list/1` - Converts an `:atomics` reference to a list of integers.
* `Abit.Atomics.member?/2` - Checks whether an integer is present in an `:atomics` reference.
* `Abit.Atomics.serialize/1` - Serializes an `:atomics` reference into a binary.
* `Abit.Atomics.deserialize/1` - Deserializes a binary into an `:atomics` reference.

### Abit.Counter - use `:atomics` as an array of N-bit counters
* `Abit.Counter.new/3` - Creates a new array of counters. Returns an `%Abit.Counter{}` struct.
* `Abit.Counter.clear/1` - Sets all elements in the counter array to 0.
* `Abit.Counter.get/2` - Returns the value of the counter at the given index.
* `Abit.Counter.put/3` - Stores a value in the counter at the given index.
* `Abit.Counter.add/3` - Adds an increment to the counter at the given index.
* `Abit.Counter.member?/2` - Returns `true` if any counter has the given value, `false` otherwise.
* `Abit.Counter.get_all_at_atomic/2` - Returns all counters packed into the atomics element at the given index.

### Abit.Bitmask - helper functions for bitmasks
* `Abit.Bitmask.set_bits_count/1` - Returns the number of bits set to 1 in the given integer.
* `Abit.Bitmask.bit_at/2` - Returns the bit at a given position in the given integer.
* `Abit.Bitmask.set_bit_at/3` - Sets a bit in the given integer at the given position to a given bit (0 or 1).
* `Abit.Bitmask.toggle_bit_at/2` - Toggles the bit at a given position in the given integer.
* `Abit.Bitmask.hamming_distance/2` - Returns the bitwise Hamming distance between two integers.
* `Abit.Bitmask.to_list/2` - Converts the given integer to a list of bits.


## License

Abit is [MIT licensed](LICENSE).
