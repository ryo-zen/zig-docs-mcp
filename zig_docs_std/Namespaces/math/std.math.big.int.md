# std.math.big.int

## Types

- Const
- Exactness
- Managed
- Mutable
- Round
- TwosCompIntLimit

## Functions

`pub fn addMulLimbWithCarry(a: Limb, b: Limb, c: Limb, carry: *Limb) Limb`
a + b \* c + \*carry, sets carry to the overflow bits

`pub fn calcDivLimbsBufferLen(a_len: usize, b_len: usize) usize`

`pub fn calcLimbLen(scalar: anytype) usize`
Returns the number of limbs needed to store `scalar`, which must be a primitive integer or float value. Note: A comptime-known upper bound of this value that may be used instead if `scalar` is not already comptime-known is `calcTwosCompLimbCount(@typeInfo(@TypeOf(scalar)).int.bits)`

`pub fn calcMulLimbsBufferLen(a_len: usize, b_len: usize, aliases: usize) usize`

`pub fn calcMulWrapLimbsBufferLen(bit_count: usize, a_len: usize, b_len: usize, aliases: usize) usize`

`pub fn calcNonZeroTwosCompLimbCount(bit_count: usize) usize`
Compute the number of limbs required to store a 2s-complement number of `bit_count` bits.

`pub fn calcPowLimbsBufferLen(a_bit_count: usize, y: usize) usize`

`pub fn calcSetStringLimbCount(base: u8, string_len: usize) usize`
Assumes `string_len` doesn't account for minus signs if the number is negative.

`pub fn calcSetStringLimbsBufferLen(base: u8, string_len: usize) usize`

`pub fn calcSqrtLimbsBufferLen(a_bit_count: usize) usize`

`pub fn calcToStringLimbsBufferLen(a_len: usize, base: u8) usize`

`pub fn calcTwosCompLimbCount(bit_count: usize) usize`
Compute the number of limbs required to store a 2s-complement number of `bit_count` bits.

`pub fn llcmp(a: []const Limb, b: []const Limb) i8`
Returns -1, 0, 1 if \|a\| \< \|b\|, \|a\| == \|b\| or \|a\| \> \|b\| respectively for limbs.
