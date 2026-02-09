# std.math.big.int.Const

A arbitrary-precision big integer, with a fixed set of immutable limbs.

### Fields

    limbs: []const Limb

Raw digits. These are:

- Little-endian ordered
- limbs.len \>= 1
- Zero is represented as limbs.len == 1 with limbs\[0\] == 0.

Accessing limbs directly should be avoided.

    positive: bool

## Types

- toFloat

## Functions

`pub fn abs(self: Const) Const`  

`pub fn bitCountAbs(self: Const) usize`  
Returns the number of bits required to represent the absolute value of an integer.

`pub fn bitCountTwosComp(self: Const) usize`  
Returns the number of bits required to represent the integer in twos-complement form.

`pub fn bitCountTwosCompForSignedness(self: Const, signedness: std.builtin.Signedness) usize`  
Returns the number of bits required to represent the integer in twos-complement form with the given signedness.

`pub fn clz(a: Const, bits: Limb) Limb`  
Returns the number of leading zeros in twos-complement form.

`pub fn ctz(a: Const, bits: Limb) Limb`  
Returns the number of trailing zeros in twos-complement form.

`pub fn dump(self: Const) void`  

`pub fn eql(a: Const, b: Const) bool`  
Returns true if `a == b`.

`pub fn eqlAbs(a: Const, b: Const) bool`  
Returns true if `|a| == |b|`.

`pub fn eqlZero(a: Const) bool`  
Returns true if `a == 0`.

`pub fn fits(self: Const, comptime T: type) bool`  
Returns whether self can fit into an integer of the requested type.

`pub fn fitsInTwosComp(self: Const, signedness: Signedness, bit_count: usize) bool`  

`pub fn format(self: Const, w: *std.Io.Writer) std.Io.Writer.Error!void`  

`pub fn formatNumber(self: Const, w: *std.Io.Writer, number: std.fmt.Number) std.Io.Writer.Error!void`  
If the absolute value of integer is greater than or equal to `pow(2, 64 * @sizeOf(usize) * 8)`, this function will fail to print the string, printing "(BigInt)" instead of a number. This is because the rendering algorithm requires reversing a string, which requires O(N) memory. See `toString` and `toStringAlloc` for a way to print big integers without failure.

`pub fn isEven(self: Const) bool`  

`pub fn isOdd(self: Const) bool`  

`pub fn negate(self: Const) Const`  

`pub fn order(a: Const, b: Const) math.Order`  
Returns `math.Order.lt`, `math.Order.eq`, `math.Order.gt` if `a < b`, `a == b` or `a > b` respectively.

`pub fn orderAbs(a: Const, b: Const) math.Order`  
Returns `math.Order.lt`, `math.Order.eq`, `math.Order.gt` if `|a| < |b|`, `|a| == |b|`, or `|a| > |b|` respectively.

`pub fn orderAgainstScalar(lhs: Const, scalar: anytype) math.Order`  
Same as `order` but the right-hand operand is a primitive integer.

`pub fn popCount(self: Const, bit_count: usize) usize`  
@popCount with two's complement semantics.

`pub fn sizeInBaseUpperBound(self: Const, base: usize) usize`  
Returns the approximate size of the integer in the given base. Negative values accommodate for the minus sign. This is used for determining the number of characters needed to print the value. It is inexact and may exceed the given value by ~1-2 bytes. TODO See if we can make this exact.

`pub fn toInt(self: Const, comptime Int: type) ConvertError!Int`  
Convert `self` to `Int`.

`pub fn toManaged(self: Const, allocator: Allocator) Allocator.Error!Managed`  
The result is an independent resource which is managed by the caller.

`pub fn toMutable(self: Const, limbs: []Limb) Mutable`  
Asserts `limbs` is big enough to store the value.

`pub fn toString(self: Const, string: []u8, base: u8, case: std.fmt.Case, limbs_buffer: []Limb) usize`  
Converts self to a string in the requested base. Asserts that `base` is in the range \[2, 36\]. `string` is a caller-provided slice of at least `sizeInBaseUpperBound` bytes, where the result is written to. Returns the length of the string. `limbs_buffer` is caller-provided memory for `toString` to use as a working area. It must have length of at least `calcToStringLimbsBufferLen`. In the case of power-of-two base, `limbs_buffer` is ignored. See also `toStringAlloc`, a higher level function than this.

`pub fn toStringAlloc(self: Const, allocator: Allocator, base: u8, case: std.fmt.Case) Allocator.Error![]u8`  
Converts self to a string in the requested base. Caller owns returned memory. Asserts that `base` is in the range \[2, 36\]. See also `toString`, a lower level function than this.

`pub fn writePackedTwosComplement(x: Const, buffer: []u8, bit_offset: usize, bit_count: usize, endian: Endian) void`  
Write the value of `x` to a packed memory `buffer`. Asserts that `buffer` is large enough to contain a value of bit-size `bit_count` at offset `bit_offset`.

`pub fn writeTwosComplement(x: Const, buffer: []u8, endian: Endian) void`  
Write the value of `x` into `buffer` Asserts that `buffer` is large enough to store the value.

## Error Sets

- ConvertError
