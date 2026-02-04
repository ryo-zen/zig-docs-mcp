# std.mem.byte_size_in_bits

The standard library currently thoroughly depends on byte size being 8 bits. (see the use of u8 throughout allocation code as the "byte" type.) Code which depends on this can reference this declaration. If we ever try to port the standard library to a non-8-bit-byte platform, this will allow us to search for things which need to be updated.

## Source Code

```
pub const byte_size_in_bits = 8
```
