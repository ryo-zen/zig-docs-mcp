# std.math.Log2Int

Returns an unsigned int type that can hold the number of bits in T - 1. Suitable for 0-based bit indices of T.

## Parameters

    T: type

## Source Code

```
pub fn Log2Int(comptime T: type) type {
    // comptime ceil log2
    if (T == comptime_int) return comptime_int;
    const bits: u16 = @typeInfo(T).int.bits;
    const log2_bits = 16 - @clz(bits - 1);
    return std.meta.Int(.unsigned, log2_bits);
}
```
