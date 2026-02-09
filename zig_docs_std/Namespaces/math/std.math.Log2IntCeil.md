# std.math.Log2IntCeil

Returns an unsigned int type that can hold the number of bits in T.

## Parameters

    T: type

## Source Code

```
pub fn Log2IntCeil(comptime T: type) type {
    // comptime ceil log2
    if (T == comptime_int) return comptime_int;
    const bits: u16 = @typeInfo(T).int.bits;
    const log2_bits = 16 - @clz(bits);
    return std.meta.Int(.unsigned, log2_bits);
}
```
