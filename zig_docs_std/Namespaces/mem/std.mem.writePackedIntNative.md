# std.mem.writePackedIntNative

Deprecated: use writePackedInt(T, bytes, bit_offset, value, .native)

## Source Code

```
pub const writePackedIntNative = switch (native_endian) {
    .little => writePackedIntLittle,
    .big => writePackedIntBig,
}
```
