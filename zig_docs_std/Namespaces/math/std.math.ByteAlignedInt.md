# std.math.ByteAlignedInt

Aligns the given integer type bit width to a width divisible by 8.

## Parameters

    T: type

## Example Usage

```
test ByteAlignedInt {
    try testing.expect(ByteAlignedInt(u0) == u0);
    try testing.expect(ByteAlignedInt(i0) == i0);
    try testing.expect(ByteAlignedInt(u3) == u8);
    try testing.expect(ByteAlignedInt(u8) == u8);
    try testing.expect(ByteAlignedInt(i111) == i112);
    try testing.expect(ByteAlignedInt(u129) == u136);
}
```

## Source Code

```
pub fn ByteAlignedInt(comptime T: type) type {
    const info = @typeInfo(T).int;
    const bits = (info.bits + 7) / 8 * 8;
    const extended_type = std.meta.Int(info.signedness, bits);
    return extended_type;
}
```
