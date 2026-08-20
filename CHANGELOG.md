# Changelog for Abit

## v0.4.0
  * Feature - Added fast atomics resetting via `Abit.clear/1` and `Abit.Counter.clear/1`.
  * Feature - Added bit toggling via `Abit.toggle_bit_at/2` and `Abit.Bitmask.toggle_bit_at/2`.
  * Feature - Added the missing set operations: `Abit.difference/2`, `Abit.symmetric_difference/2`, and `Abit.invert/1`.
  * Deprecation - Deprecated `Abit.merge/2` in favor of `Abit.union/2` to align with standard set theory terminology.

## v0.3.3
  * Feature - Added `Abit.Atomics.serialize/1` and `Abit.Atomics.deserialize/1`.

## v0.3.2
  * Fix - Fixed a compile warning caused by using `^^^/2` in `Abit.Counter`.

## v0.3.1
  * Fix - Restored compatibility with Elixir 1.7 by avoiding `Kernel.floor/1` and `Kernel.ceil/1`.

## v0.3.0
  * BREAKING - Removed `Abit.Matrix` and extracted it to [matrax](https://hex.pm/packages/matrax).

## v0.2.4
  * Feature - Implemented the `Enumerable` protocol for `Abit.Counter`.

## v0.2.3
  * Feature - Added `add/3`, `exchange/3`, `compare_exchange/4`, `min/1`, `max/1`, and other functions to `Abit.Matrix`.
  * Feature - Implemented the `Enumerable` protocol for `Abit.Matrix`.
  * Feature - Added `Abit.Bitmask.to_list/2`.
  * Feature - Added `Abit.to_list/1`.

## v0.2.2
  * Feature - Added `Abit.Matrix` for working with atomics as an M x N matrix.

## v0.2.1
  * Performance - Improved the performance of functions in `Abit` and `Abit.Bitmask`.

## v0.2.0

### Abit
  * BREAKING - Renamed `set_bit/3` to `set_bit_at/3` for consistency with the `Abit.Bitmask` API.

### Abit.Counter
  * BREAKING - Added the `wrap_around` option. Wraparound is now disabled by default.
  * BREAKING - Replaced the custom signed and unsigned integer matching with the built-in implementation. Signed integers now wrap around as they do in Elixir.
  * BREAKING - Changed the return value of `put/3` and `add/3` to `{:ok, {index, final_value}}`, or `{:error, :value_out_of_bounds}` when `wrap_around` is `false` and the value is out of bounds.
