# std.math.big.int.Mutable

A arbitrary-precision big integer, with a fixed set of mutable limbs.

### Fields

    limbs: []Limb

Raw digits. These are:

- Little-endian ordered
- limbs.len \>= 1
- Zero is represented as limbs.len == 1 with limbs\[0\] == 0.

Accessing limbs directly should be avoided. These are allocated limbs; the `len` field tells the valid range.

    len: usize

    positive: bool

## Types

- toFloat

## Functions

`pub fn abs(self: *Mutable) void`
Modify to become the absolute value

`pub fn add(r: *Mutable, a: Const, b: Const) void`
r = a + b

`pub fn addSat(r: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize) void`
r = a + b with 2s-complement saturating semantics. r, a and b may be aliases.

`pub fn addScalar(r: *Mutable, a: Const, scalar: anytype) void`
r = a + scalar

`pub fn addWrap(r: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize) bool`
r = a + b with 2s-complement wrapping semantics. Returns whether overflow occurred. r, a and b may be aliases

`pub fn bitAnd(r: *Mutable, a: Const, b: Const) void`
r = a & b under 2s complement semantics. r may alias with a or b.

`pub fn bitNotWrap(r: *Mutable, a: Const, signedness: Signedness, bit_count: usize) void`
r = ~a under 2s complement wrapping semantics. r may alias with a.

`pub fn bitOr(r: *Mutable, a: Const, b: Const) void`
r = a \| b under 2s complement semantics. r may alias with a or b.

`pub fn bitReverse(r: *Mutable, a: Const, signedness: Signedness, bit_count: usize) void`
r = @bitReverse(a) with 2s-complement semantics. r and a may be aliases.

`pub fn bitXor(r: *Mutable, a: Const, b: Const) void`
r = a ^ b under 2s complement semantics. r may alias with a or b.

`pub fn byteSwap(r: *Mutable, a: Const, signedness: Signedness, byte_count: usize) void`
r = @byteSwap(a) with 2s-complement semantics. r and a may be aliases.

`pub fn clone(other: Mutable, limbs: []Limb) Mutable`
Clones an Mutable and returns a new Mutable with the same value. The new Mutable is a deep copy and can be modified separately from the original. Asserts that limbs is big enough to store the value.

`pub fn copy(self: *Mutable, other: Const) void`
Copies the value of a Const to an existing Mutable so that they both have the same value. Asserts the value fits in the limbs buffer.

`pub fn divFloor( q: *Mutable, r: *Mutable, a: Const, b: Const, limbs_buffer: []Limb, ) void`
q = a / b (rem r)

`pub fn divTrunc( q: *Mutable, r: *Mutable, a: Const, b: Const, limbs_buffer: []Limb, ) void`
q = a / b (rem r)

`pub fn dump(self: Mutable) void`

`pub fn eqlZero(self: Mutable) bool`
Returns true if `a == 0`.

`pub fn format(self: Mutable, w: *std.Io.Writer) std.Io.Writer.Error!void`

`pub fn formatNumber(self: Mutable, w: *std.Io.Writer, n: std.fmt.Number) std.Io.Writer.Error!void`
If the absolute value of integer is greater than or equal to `pow(2, 64 * @sizeOf(usize) * 8)`, this function will fail to print the string, printing "(BigInt)" instead of a number. This is because the rendering algorithm requires reversing a string, which requires O(N) memory. See `Const.toString` and `Const.toStringAlloc` for a way to print big integers without failure.

`pub fn gcd(rma: *Mutable, x: Const, y: Const, limbs_buffer: *std.array_list.Managed(Limb)) !void`
rma may alias x or y. x and y may alias each other. Asserts that `rma` has enough limbs to store the result. Upper bound is `@min(x.limbs.len, y.limbs.len)`.

`pub fn gcdNoAlias(rma: *Mutable, x: Const, y: Const, limbs_buffer: *std.array_list.Managed(Limb)) !void`
rma may not alias x or y. x and y may alias each other. Asserts that `rma` has enough limbs to store the result. Upper bound is given by `calcGcdNoAliasLimbLen`.

`pub fn init(limbs_buffer: []Limb, value: anytype) Mutable`
`value` is a primitive integer type. Asserts the value fits within the provided `limbs_buffer`. Note: `calcLimbLen` can be used to figure out how big an array to allocate for `limbs_buffer`.

`pub fn mul(rma: *Mutable, a: Const, b: Const, limbs_buffer: []Limb, allocator: ?Allocator) void`
rma = a \* b

`pub fn mulNoAlias(rma: *Mutable, a: Const, b: Const, allocator: ?Allocator) void`
rma = a \* b

`pub fn mulWrap( rma: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize, limbs_buffer: []Limb, allocator: ?Allocator, ) void`
rma = a \* b with 2s-complement wrapping semantics.

`pub fn mulWrapNoAlias( rma: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize, allocator: ?Allocator, ) void`
rma = a \* b with 2s-complement wrapping semantics.

`pub fn negate(self: *Mutable) void`

`pub fn normalize(r: *Mutable, length: usize) void`
Normalize a possible sequence of leading zeros.

`pub fn popCount(r: *Mutable, a: Const, bit_count: usize) void`
r = @popCount(a) with 2s-complement semantics. r and a may be aliases.

`pub fn pow(r: *Mutable, a: Const, b: u32, limbs_buffer: []Limb) void`
q = a ^ b

`pub fn readPackedTwosComplement( x: *Mutable, buffer: []const u8, bit_offset: usize, bit_count: usize, endian: Endian, signedness: Signedness, ) void`
Read the value of `x` from a packed memory `buffer`. Asserts that `buffer` is large enough to contain a value of bit-size `bit_count` at offset `bit_offset`.

`pub fn readTwosComplement( x: *Mutable, buffer: []const u8, bit_count: usize, endian: Endian, signedness: Signedness, ) void`
Read the value of `x` from `buffer`. Asserts that `buffer` is large enough to contain a value of bit-size `bit_count`.

`pub fn saturate(r: *Mutable, a: Const, signedness: Signedness, bit_count: usize) void`
Saturate an integer to a number of bits, following 2s-complement semantics. r may alias a.

`pub fn set(self: *Mutable, value: anytype) void`
Sets the Mutable to value. Value must be an primitive integer type. Asserts the value fits within the limbs buffer. Note: `calcLimbLen` can be used to figure out how big the limbs buffer needs to be to store a specific value.

`pub fn setFloat(self: *Mutable, value: anytype, round: Round) Exactness`
Sets the Mutable to a float value rounded according to `round`. Returns whether the conversion was exact (`round` had no effect on the result).

`pub fn setString( self: *Mutable, base: u8, value: []const u8, ) error{InvalidCharacter}!void`
Set self from the string representation `value`.

`pub fn setTwosCompIntLimit( r: *Mutable, limit: TwosCompIntLimit, signedness: Signedness, bit_count: usize, ) void`
Set self to either bound of a 2s-complement integer. Note: The result is still sign-magnitude, not twos complement! In order to convert the result to twos complement, it is sufficient to take the absolute value.

`pub fn shiftLeft(r: *Mutable, a: Const, shift: usize) void`
r = a \<\< shift, in other words, r = a \* 2^shift

`pub fn shiftLeftSat(r: *Mutable, a: Const, shift: usize, signedness: Signedness, bit_count: usize) void`
r = a \<\<\| shift with 2s-complement saturating semantics.

`pub fn shiftRight(r: *Mutable, a: Const, shift: usize) void`
r = a \>\> shift r and a may alias.

`pub fn sqrNoAlias(rma: *Mutable, a: Const, opt_allocator: ?Allocator) void`
rma = a \* a

`pub fn sqrt( r: *Mutable, a: Const, limbs_buffer: []Limb, ) void`
r = ⌊√a⌋

`pub fn sub(r: *Mutable, a: Const, b: Const) void`
r = a - b

`pub fn subSat(r: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize) void`
r = a - b with 2s-complement saturating semantics. r, a and b may be aliases.

`pub fn subWrap(r: *Mutable, a: Const, b: Const, signedness: Signedness, bit_count: usize) bool`
r = a - b with 2s-complement wrapping semantics. Returns whether any overflow occurred.

`pub fn swap(self: *Mutable, other: *Mutable) void`
Efficiently swap an Mutable with another. This swaps the limb pointers and a full copy is not performed. The address of the limbs field will not be the same after this function.

`pub fn toConst(self: Mutable) Const`

`pub fn toInt(self: Mutable, comptime Int: type) ConvertError!Int`
Convert `self` to `Int`.

`pub fn toManaged(self: Mutable, allocator: Allocator) Managed`
Asserts that the allocator owns the limbs memory. If this is not the case, use `toConst().toManaged()`.

`pub fn truncate(r: *Mutable, a: Const, signedness: Signedness, bit_count: usize) void`
Truncate an integer to a number of bits, following 2s-complement semantics. `r` may alias `a`.

## Error Sets

- ConvertError
