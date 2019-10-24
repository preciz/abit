# Changelog for Abit

## v0.3.0
  * BREAKING - removed `Abit.Matrix` module. Extracted to [matrax](https://hex.pm/packages/matrax).

## v0.2.4
  * Feature - `Abit.Counter` implements `Enumerable` protocol

## v0.2.3
  * Feature - `Abit.Matrix` implements `add/3`, `exchange/3`, `compare_exchange/4`, `min/1`, `max/1`, ... functions.
  * Feature - `Abit.Matrix` implements the `Enumerable` protocol
  * Feature - `Abit.Bitmask` implements `to_list/2`function.
  * Feature - `Abit` implements `to_list/1` function.

## v0.2.2
  * Feature - `Abit.Matrix` module for working with atomics as an M x N matrix.

## v0.2.1
  * Performance - improvements for the `Abit` & `Abit.Bitmask` module functions

## v0.2.0

### Abit
  * BREAKING - renamed function `set_bit/3` to `set_bit_at/3` to make it consistent with the API of the Bitmask module.

### Abit.Counter
  * BREAKING - Added an option `wrap_around` to set wrap around behavior. By default wrap around is disabled from now on.
  * BREAKING - Using built-in signed/unsigned implementation of integer matching instead of the custom one. Signed integers now wrap around the same way as in Elixir.
  * BREAKING - The return value of `put/3` and `add/3` changed to `{:ok, {index, final_value}}` or `{:error, :value_out_of_bounds}` if the option `wrap_around` is set to false and value is out of bounds.

