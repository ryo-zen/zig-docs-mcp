# std.mem.readPackedIntNative

Deprecated: use readPackedInt(T, bytes, bit_offset, value, .native)

## Source Code

```
pub const readPackedIntNative = switch (native_endian) {
    .little => readPackedIntLittle,
    .big => readPackedIntBig,
}
```
