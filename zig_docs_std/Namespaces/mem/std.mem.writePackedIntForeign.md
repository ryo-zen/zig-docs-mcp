# std.mem.writePackedIntForeign

Deprecated: use writePackedInt(T, bytes, bit_offset, value, .foreign)

## Source Code

```
pub const writePackedIntForeign = switch (native_endian) {
    .little => writePackedIntBig,
    .big => writePackedIntLittle,
}
```
