# std.Random

`std.Random` is the root import of `Random.zig`, a type-erased interface for random byte generation plus helpers for common random values.

## Source Declaration

```zig
pub const Random = @import("Random.zig");
```

## Interface Fields

- `ptr: *anyopaque`
- `fillFn: *const fn (ptr: *anyopaque, buf: []u8) void`

`ptr` points at implementation state. `fillFn` fills a byte buffer from that state. Code usually obtains this interface from a PRNG or CSPRNG object's `random` method rather than constructing it directly.

## Engines and Namespaces

- `DefaultPrng = Xoshiro256`
- `DefaultCsprng = ChaCha`
- `Ascon`
- `ChaCha`
- `Isaac64`
- `Pcg`
- `RomuTrio`
- `Sfc64`
- `SplitMix64`
- `Xoroshiro128`
- `Xoshiro256`
- `lcg`
- `ziggurat`

The source notes that engines should be initialized from an external source. Use a cryptographically secure source when security matters; ordinary PRNGs are faster and use less stack space.

## Nested Types

### `IoSource`

`IoSource` adapts an `std.Io` backend to the `std.Random` interface by calling `io.random`.

## Core Functions

### `pub fn init(pointer: anytype, comptime fillFn: fn (ptr: @TypeOf(pointer), buf: []u8) void) Random`

Creates a `Random` interface from a single-item pointer to a struct and a fill function.

### `pub fn bytes(r: Random, buf: []u8) void`

Fills `buf` with random bytes.

### `pub fn array(r: Random, comptime E: type, comptime N: usize) [N]E`

Returns an array filled from random bytes.

### `pub fn boolean(r: Random) bool`

Returns a random boolean.

### `pub fn int(r: Random, comptime T: type) T`

Returns an evenly distributed integer across the full range of `T`.

### `pub fn uintLessThan(r: Random, comptime T: type, less_than: T) T`

Returns an evenly distributed unsigned integer in `0 <= i < less_than`.

### `pub fn uintAtMost(r: Random, comptime T: type, at_most: T) T`

Returns an evenly distributed unsigned integer in `0 <= i <= at_most`.

### `pub fn intRangeLessThan(r: Random, comptime T: type, at_least: T, less_than: T) T`

Returns an evenly distributed integer in `at_least <= i < less_than`.

### `pub fn intRangeAtMost(r: Random, comptime T: type, at_least: T, at_most: T) T`

Returns an evenly distributed integer in `at_least <= i <= at_most`.

### `pub fn float(r: Random, comptime T: type) T`

Returns a floating-point value in the range `[0, 1)`.

### `pub fn floatNorm(r: Random, comptime T: type) T`

Returns a normally distributed floating-point value with mean 0 and standard deviation 1.

### `pub fn floatExp(r: Random, comptime T: type) T`

Returns an exponentially distributed floating-point value with rate parameter 1.

### `pub fn enumValue(r: Random, comptime EnumType: type) EnumType`

Returns a random enum value. Results may vary across targets because the implementation uses `usize` as an index type.

### `pub fn enumValueWithIndex(r: Random, comptime EnumType: type, comptime Index: type) EnumType`

Returns a random enum value using an explicit unsigned index type for more portable distribution.

### `pub fn shuffle(r: Random, comptime T: type, buf: []T) void`

Shuffles a slice in place. Results may vary across targets because the implementation uses `usize` as an index type.

### `pub fn shuffleWithIndex(r: Random, comptime T: type, buf: []T, comptime Index: type) void`

Shuffles a slice in place using an explicit unsigned index type.

### `pub fn weightedIndex(r: Random, comptime T: type, proportions: []const T) usize`

Selects an index weighted by the numeric proportions in the slice.

### `pub fn limitRangeBiased(comptime T: type, random_int: T, less_than: T) T`

Maps a full-range unsigned random integer into `0 <= result < less_than` with minor bias.

## Biased Helpers

The `uintLessThanBiased`, `uintAtMostBiased`, `intRangeLessThanBiased`, and `intRangeAtMostBiased` variants use constant-time range limiting but may introduce bias.

## See Also

- `std.crypto`
- `std.Io.random`
- `std.Io.randomSecure`
