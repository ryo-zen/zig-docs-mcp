# std.testing.backend_can_print

## Source Code

```
pub const backend_can_print = switch (builtin.zig_backend) {
    .stage2_aarch64,
    .stage2_powerpc,
    .stage2_riscv64,
    .stage2_spirv,
    => false,
    else => true,
}
```
