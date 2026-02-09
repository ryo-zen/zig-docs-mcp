# std.math.big.int.Managed

An arbitrary-precision big integer along with an allocator which manages the memory.

Memory is allocated as needed to ensure operations never overflow. The range is bounded only by available memory.

### Fields

    allocator: Allocator

Allocator used by the Managed when requesting memory.

    limbs: []Limb

Raw digits. These are:

- Little-endian ordered
- limbs.len \>= 1
- Zero is represent as Managed.len() == 1 with limbs\[0\] == 0.

Accessing limbs directly should be avoided.

    metadata: usize

High bit is the sign bit. If set, Managed is negative, else Managed is positive. The remaining bits represent the number of limbs used by Managed.

## Types

- toFloat

## Values

|  |  |  |
|----|----|----|
| default_capacity |  | Default number of limbs to allocate on creation of a `Managed`. |
| sign_bit | `usize` |  |

## Functions

`pub fn abs(self: *Managed) void`  
Make positive.

`pub fn add(r: *Managed, a: *const Managed, b: *const Managed) Allocator.Error!void`  
r = a + b

`pub fn addSat(r: *Managed, a: *const Managed, b: *const Managed, signedness: Signedness, bit_count: usize) Allocator.Error!void`  
r = a + b with 2s-complement saturating semantics.

`pub fn addScalar(r: *Managed, a: *const Managed, scalar: anytype) Allocator.Error!void`  
r = a + scalar

`pub fn addWrap( r: *Managed, a: *const Managed, b: *const Managed, signedness: Signedness, bit_count: usize, ) Allocator.Error!bool`  
r = a + b with 2s-complement wrapping semantics. Returns whether any overflow occurred.

`pub fn bitAnd(r: *Managed, a: *const Managed, b: *const Managed) !void`  
r = a & b

`pub fn bitCountAbs(self: Managed) usize`  
Returns the number of bits required to represent the absolute value of an integer.

`pub fn bitCountTwosComp(self: Managed) usize`  
Returns the number of bits required to represent the integer in twos-complement form.

`pub fn bitNotWrap(r: *Managed, a: *const Managed, signedness: Signedness, bit_count: usize) !void`  
r = ~a under 2s-complement wrapping semantics. r and a may alias.

`pub fn bitOr(r: *Managed, a: *const Managed, b: *const Managed) !void`  
r = a \| b

`pub fn bitXor(r: *Managed, a: *const Managed, b: *const Managed) !void`  
r = a ^ b

`pub fn clone(other: Managed) !Managed`  
Returns a `Managed` with the same value. The returned `Managed` is a deep copy and can be modified separately from the original, and its resources are managed separately from the original.

`pub fn cloneWithDifferentAllocator(other: Managed, allocator: Allocator) !Managed`  

`pub fn copy(self: *Managed, other: Const) !void`  
Copies the value of the integer to an existing `Managed` so that they both have the same value. Extra memory will be allocated if the receiver does not have enough capacity.

`pub fn deinit(self: *Managed) void`  
Frees all associated memory.

`pub fn divFloor(q: *Managed, r: *Managed, a: *const Managed, b: *const Managed) !void`  
q = a / b (rem r)

`pub fn divTrunc(q: *Managed, r: *Managed, a: *const Managed, b: *const Managed) !void`  
q = a / b (rem r)

`pub fn dump(self: Managed) void`  
Debugging tool: prints the state to stderr.

`pub fn ensureAddCapacity(r: *Managed, a: *const Managed, b: *const Managed) !void`  
Use this function before doing `add` if some of your parameters alias each other

`pub fn ensureAddScalarCapacity(r: *Managed, a: *const Managed, scalar: anytype) !void`  
Use this function before doing `addScalar` if some of your parameters alias each other

`pub fn ensureCapacity(self: *Managed, capacity: usize) !void`  
Ensures an Managed has enough space allocated for capacity limbs. If the Managed does not have sufficient capacity, the exact amount will be allocated. This occurs even if the requested capacity is only greater than the current capacity by one limb.

`pub fn ensureMulCapacity(rma: *Managed, a: *const Managed, b: *const Managed) !void`  
Use this function before doing `mul` if some of your parameters alias each other

`pub fn ensureTwosCompCapacity(r: *Managed, bit_count: usize) !void`  

`pub fn eql(a: Managed, b: Managed) bool`  
Returns true if a == b.

`pub fn eqlAbs(a: Managed, b: Managed) bool`  
Returns true if \|a\| == \|b\|.

`pub fn eqlZero(a: Managed) bool`  
Returns true if a == 0.

`pub fn fits(self: Managed, comptime T: type) bool`  
Returns whether self can fit into an integer of the requested type.

`pub fn fitsInTwosComp(self: Managed, signedness: Signedness, bit_count: usize) bool`  

`pub fn format(self: Managed, w: *std.Io.Writer) std.Io.Writer.Error!void`  
To allow `std.fmt.format` to work with `Managed`.

`pub fn formatNumber(self: Managed, w: *std.Io.Writer, n: std.fmt.Number) std.Io.Writer.Error!void`  
If the absolute value of integer is greater than or equal to `pow(2, 64 * @sizeOf(usize) * 8)`, this function will fail to print the string, printing "(BigInt)" instead of a number. This is because the rendering algorithm requires reversing a string, which requires O(N) memory. See `toString` and `toStringAlloc` for a way to print big integers without failure.

`pub fn gcd(rma: *Managed, x: *const Managed, y: *const Managed) !void`  
rma may alias x or y. x and y may alias each other.

`pub fn init(allocator: Allocator) !Managed`  
Creates a new `Managed`. `default_capacity` limbs will be allocated immediately. The integer value after initializing is `0`.

`pub fn initCapacity(allocator: Allocator, capacity: usize) !Managed`  
Creates a new Managed with a specific capacity. If capacity \< default_capacity then the default capacity will be used instead. The integer value after initializing is `0`.

`pub fn initSet(allocator: Allocator, value: anytype) !Managed`  
Creates a new `Managed` with value `value`.

`pub fn isEven(self: Managed) bool`  

`pub fn isOdd(self: Managed) bool`  

`pub fn isPositive(self: Managed) bool`  
Returns whether an Managed is positive.

`pub fn len(self: Managed) usize`  
Returns the number of limbs currently in use.

`pub fn mul(rma: *Managed, a: *const Managed, b: *const Managed) !void`  
rma = a \* b

`pub fn mulWrap( rma: *Managed, a: *const Managed, b: *const Managed, signedness: Signedness, bit_count: usize, ) !void`  
rma = a \* b with 2s-complement wrapping semantics.

`pub fn negate(self: *Managed) void`  
Negate the sign.

`pub fn normalize(r: *Managed, length: usize) void`  
Normalize a possible sequence of leading zeros.

`pub fn order(a: Managed, b: Managed) math.Order`  
Returns math.Order.lt, math.Order.eq, math.Order.gt if a \< b, a == b or a \> b respectively.

`pub fn orderAbs(a: Managed, b: Managed) math.Order`  
Returns math.Order.lt, math.Order.eq, math.Order.gt if \|a\| \< \|b\|, \|a\| == \|b\| or \|a\| \> \|b\| respectively.

`pub fn popCount(r: *Managed, a: *const Managed, bit_count: usize) !void`  
r = @popCount(a) with 2s-complement semantics. r and a may be aliases.

`pub fn pow(rma: *Managed, a: *const Managed, b: u32) !void`  

`pub fn saturate(r: *Managed, a: *const Managed, signedness: Signedness, bit_count: usize) !void`  
r = saturate(Int(signedness, bit_count), a)

`pub fn set(self: *Managed, value: anytype) Allocator.Error!void`  
Sets an Managed to value. Value must be an primitive integer type.

`pub fn setLen(self: *Managed, new_len: usize) void`  
Sets the length of an Managed.

`pub fn setMetadata(self: *Managed, positive: bool, length: usize) void`  

`pub fn setSign(self: *Managed, positive: bool) void`  
Sets the sign of an Managed.

`pub fn setString(self: *Managed, base: u8, value: []const u8) !void`  
Set self from the string representation `value`.

`pub fn setTwosCompIntLimit( r: *Managed, limit: TwosCompIntLimit, signedness: Signedness, bit_count: usize, ) !void`  
Set self to either bound of a 2s-complement integer. Note: The result is still sign-magnitude, not twos complement! In order to convert the result to twos complement, it is sufficient to take the absolute value.

`pub fn shiftLeft(r: *Managed, a: *const Managed, shift: usize) !void`  
r = a \<\< shift, in other words, r = a \* 2^shift r and a may alias.

`pub fn shiftLeftSat(r: *Managed, a: *const Managed, shift: usize, signedness: Signedness, bit_count: usize) !void`  
r = a \<\<\| shift with 2s-complement saturating semantics. r and a may alias.

`pub fn shiftRight(r: *Managed, a: *const Managed, shift: usize) !void`  
r = a \>\> shift r and a may alias.

`pub fn sizeInBaseUpperBound(self: Managed, base: usize) usize`  
Returns the approximate size of the integer in the given base. Negative values accommodate for the minus sign. This is used for determining the number of characters needed to print the value. It is inexact and may exceed the given value by ~1-2 bytes.

`pub fn sqr(rma: *Managed, a: *const Managed) !void`  
r = a \* a

`pub fn sqrt(rma: *Managed, a: *const Managed) !void`  
r = ⌊√a⌋

`pub fn sub(r: *Managed, a: *const Managed, b: *const Managed) !void`  
r = a - b

`pub fn subSat( r: *Managed, a: *const Managed, b: *const Managed, signedness: Signedness, bit_count: usize, ) Allocator.Error!void`  
r = a - b with 2s-complement saturating semantics.

`pub fn subWrap( r: *Managed, a: *const Managed, b: *const Managed, signedness: Signedness, bit_count: usize, ) Allocator.Error!bool`  
r = a - b with 2s-complement wrapping semantics. Returns whether any overflow occurred.

`pub fn swap(self: *Managed, other: *Managed) void`  
Efficiently swap a `Managed` with another. This swaps the limb pointers and a full copy is not performed. The address of the limbs field will not be the same after this function.

`pub fn toConst(self: Managed) Const`  

`pub fn toInt(self: Managed, comptime Int: type) ConvertError!Int`  
Convert `self` to `Int`.

`pub fn toMutable(self: Managed) Mutable`  

`pub fn toString(self: Managed, allocator: Allocator, base: u8, case: std.fmt.Case) ![]u8`  
Converts self to a string in the requested base. Memory is allocated from the provided allocator and not the one present in self.

`pub fn truncate(r: *Managed, a: *const Managed, signedness: Signedness, bit_count: usize) !void`  
r = truncate(Int(signedness, bit_count), a)

## Error Sets

- ConvertError
