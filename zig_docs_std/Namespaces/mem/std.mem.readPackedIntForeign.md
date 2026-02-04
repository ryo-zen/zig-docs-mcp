# std.mem.readPackedIntForeign

Deprecated: use readPackedInt(T, bytes, bit_offset, value, .foreign)

## Source Code

```
pub const readPackedIntForeign = switch (native_endian) {
    .little => readPackedIntBig,
    .big => readPackedIntLittle,
}
```
