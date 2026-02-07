# std.testing.allocator_instance

## Source Code

```
pub var allocator_instance: std.heap.GeneralPurposeAllocator(.{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0,
    .resize_stack_traces = true,
    // A unique value so that when a default-constructed
    // GeneralPurposeAllocator is incorrectly passed to testing allocator, or
    // vice versa, panic occurs.
    .canary = @truncate(0x2731e675c3a701ba),
}) = b: {
    if (!builtin.is_test) @compileError("testing allocator used when not testing");
    break :b .init;
}
```
