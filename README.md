# Abit

[![test](https://github.com/preciz/abit/actions/workflows/test.yml/badge.svg)](https://github.com/preciz/abit/actions/workflows/test.yml)

Use `:atomics` as a bit array or as an array of N-bit counters.

Documentation can be found at [https://hexdocs.pm/abit](https://hexdocs.pm/abit).

## Installation

**Note**: it requires OTP-21.2.1 or later.

Add `abit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abit, "~> 0.3"}
  ]
end
```

## API summary
See [https://hexdocs.pm/abit](https://hexdocs.pm/abit) for full documentation.

### Abit - use `:atomics` as a bit array
* `Abit.bit_count/1` - Returns count of bits in atomics.
* `Abit.union/2` - Unions bits of 2 atomics using Bitwise OR.
* `Abit.intersect/2` - Intersects bits of 2 atomics using Bitwise AND.
* `Abit.difference/2` - Clears bits in left atomics that are set in right using Bitwise AND NOT.
* `Abit.symmetric_difference/2` - Symmetric difference of 2 atomics using Bitwise XOR.
* `Abit.invert/1` - Inverts all bits in atomics using Bitwise NOT.
* `Abit.bit_position/1` - Returns the bit's position in an atomics array.
* `Abit.bit_at/2` - Returns the bit at a given position from atomics.
* `Abit.set_bit_at/3` - Sets the bit in atomics at the given position to the given bit (0 or 1).
* `Abit.toggle_bit_at/2` - Toggles the bit in atomics at the given position.
* `Abit.clear/1` - Sets all elements in the atomics reference to 0.
* `Abit.set_bits_count/1` - Returns the number of bits set to 1 in atomics.
* `Abit.hamming_distance/2` - Returns the bitwise hamming distance between the 2 given atomics.
* `Abit.to_list/1` - Returns a flat list of every atomic value converted into a list of bits.

### Abit.Atomics - utility functions for working with Erlang's :atomics
* `Abit.Atomics.to_list/1` - Converts an :atomics reference to a list of integers.
* `Abit.Atomics.member?/2` - Checks if an integer is present in the :atomics reference.
* `Abit.Atomics.serialize/1` - Serializes an :atomics reference into a binary.
* `Abit.Atomics.deserialize/1` - Deserializes a binary into an :atomics reference.

### Abit.Counter - use `:atomics` as an array of N-bit counters
* `Abit.Counter.new/3` - Create a new array of counters. Returns %Abit.Counter{} struct.
* `Abit.Counter.clear/1` - Sets all elements in the counter array to 0.
* `Abit.Counter.get/2` - Returns the value of counter at the given index.
* `Abit.Counter.put/3` - Puts the value into counter at the given index.
* `Abit.Counter.add/3` - Adds the increment to counter at the given index.
* `Abit.Counter.member?/2` - Returns `true` if any counter has the given value, `false` otherwise.
* `Abit.Counter.get_all_at_atomic/2` - Returns all counters from atomics at a given index.

### Abit.Bitmask - helper functions for bitmasks
* `Abit.Bitmask.set_bits_count/1` - Returns the number of bits set to 1 in the given integer.
* `Abit.Bitmask.bit_at/2` - Returns the bit at a given position in the given integer.
* `Abit.Bitmask.set_bit_at/3` - Sets a bit in the given integer at the given position to a given bit (0 or 1).
* `Abit.Bitmask.toggle_bit_at/2` - Toggles the bit at a given position in the given integer.
* `Abit.Bitmask.hamming_distance/2` - Returns the bitwise hamming distance between the 2 given integers.
* `Abit.Bitmask.to_list/2` - Converts the given integer to a list of bits.


## License

Abit is [MIT licensed](LICENSE).
