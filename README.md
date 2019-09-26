# Abit

Helper functions to use :atomics as a bit array in Elixir.

## Installation

Add `abit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abit, "~> 0.1.0"}
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

Documentation can be found at [https://hexdocs.pm/abit](https://hexdocs.pm/abit).

