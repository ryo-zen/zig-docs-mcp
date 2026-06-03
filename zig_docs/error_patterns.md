# Error Handling Patterns

Practical Zig 0.16 patterns for `try`, `catch`, `defer`, `errdefer`, cleanup ownership, and batch error handling.

Policy-level guidance lives in [Error Handling Playbook](error_handling.md). This page focuses on code shape.

## Runnable Examples

- `zig test zig_docs_std/Examples/error_patterns.tests.zig`
- `zig test zig_docs_std/Examples/error_handling_playbook.tests.zig`
- `zig test zig_docs_std/Examples/errors_optionals_language.tests.zig`

## Capture Patterns

### Error Capture

`catch |err|` captures an error value. Handle the expected errors and propagate the rest.

```zig
const value = parseAsInt(input) catch |err| switch (err) {
    error.InvalidFormat => try parseFallback(input),
    else => return err,
};
```

Capturing errors is by value; there is no pointer form for an error capture.

### Optional Value Capture

`if (optional) |value|` captures the payload by value.

```zig
if (maybe_thing) |thing| {
    var mutable = thing;
    mutable.deinit();
}
```

Use this when the optional payload should be copied out, or when you need a mutable local copy of a value payload.

### Optional Pointer Capture

`if (optional) |*value|` captures a pointer to the payload. Mutability depends on the optional being captured:

- mutable optional lvalue: `*T`
- const optional lvalue or temporary value: `*const T`

```zig
var maybe: ?Thing = .{ .value = 41 };

if (maybe) |*thing| {
    thing.value += 1;
}
```

This is useful for modifying a payload in place. It is also useful in `errdefer` cleanup when the optional field itself is mutable.

## `defer` and `errdefer`

Use `defer` for cleanup that must always happen when the scope exits.

```zig
const bytes = try allocator.alloc(u8, 1024);
defer allocator.free(bytes);
```

Use `errdefer` when ownership transfers on success but must be cleaned up if a later operation fails.

```zig
const resource = try allocator.create(Resource);
errdefer allocator.destroy(resource);

try resource.init();
return resource;
```

Defers run in reverse order. Put each cleanup immediately after the acquisition it cleans up.

## EOF as a Normal Path

End-of-stream is often a normal control-flow path, not a failure.

For delimiter-based reading in Zig 0.16, `std.Io.Reader.takeDelimiter` returns `null` at EOF:

```zig
var reader = std.Io.Reader.fixed("a\nb\nc");

while (try reader.takeDelimiter('\n')) |line| {
    processLine(line);
}
```

For APIs that return `error.EndOfStream`, handle that error explicitly and propagate the rest.

```zig
while (true) {
    const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
        error.EndOfStream => break,
        else => return err,
    };

    processLine(line);
}
```

For cancelable `std.Io` operations, `error.Canceled` is also an expected control-flow path. Usually propagate it or clean up and re-arm cancelation with `io.recancel()` when local policy consumes it.

## Fallback Parsing

A `catch` block can produce the same result type as the success path. Use a labeled block when the fallback needs multiple statements.

```zig
const value = parseAsInt(input) catch |err| switch (err) {
    error.InvalidFormat => blk: {
        const float_value = try parseAsFloat(input);
        break :blk @as(i32, @intFromFloat(float_value));
    },
    else => return err,
};
```

Keep fallback behavior narrow. Do not treat all errors as retryable or convertible.

## Optional Partial Cleanup

Optionals are useful for tracking partial initialization.

```zig
var partial: ?Thing = null;
errdefer if (partial) |*thing| {
    thing.deinit();
};

partial = try createThing();
try partial.?.connect();

return partial.?;
```

The `errdefer` only runs if a later error occurs. On success, ownership leaves the function with the returned value.

## Accumulate Errors

Some batch operations should continue after per-item failures.

```zig
const Summary = struct { succeeded: usize, failed: usize };

fn processAll(items: []const Item) Summary {
    var summary = Summary{ .succeeded = 0, .failed = 0 };

    for (items) |item| {
        item.process() catch {
            summary.failed += 1;
            continue;
        };
        summary.succeeded += 1;
    }

    return summary;
}
```

Use this only when a failed item does not invalidate the rest of the batch.

## Progressive Cleanup

For multi-step construction, pair each successful acquisition with an `errdefer`.

```zig
fn makeBundle(allocator: std.mem.Allocator) !Bundle {
    const a = try allocator.alloc(u8, 8);
    errdefer allocator.free(a);

    const b = try allocator.alloc(u8, 16);
    errdefer allocator.free(b);

    return .{ .a = a, .b = b };
}
```

On failure after `a` is allocated, `a` is freed. On failure after `b` is allocated, `b` is freed first, then `a`. On success, neither `errdefer` runs and the caller owns both allocations.

## Error Union Unwrapping

Use a default only when the default is valid policy for that call site:

```zig
const value = parseOptionalLimit(input) catch default_limit;
```

Use `catch unreachable` only when the error is proven impossible by construction:

```zig
const text = std.fmt.bufPrint(&buffer, "id-{d}", .{id}) catch unreachable;
```

If the proof depends on external input, configuration, I/O, allocation, or future code staying unchanged, return or handle the error instead.

## Gotchas

1. `catch {}` discards the error; use it only when the exact error is irrelevant by policy.
2. `catch unreachable` turns a mistaken assumption into a runtime panic.
3. `errdefer` only applies to errors after the `errdefer` statement is reached.
4. Pointer capture mutability follows the captured optional's mutability.
5. Logging an error and replacing it with a generic error can make caller policy worse.
6. Swallowing `error.Canceled` without a cancelation policy can break `std.Io` task shutdown.

## See Also

- [Error Handling Playbook](error_handling.md)
- [Errors](errors.md)
- [defer](defer.md)
- [Memory Allocator Strategy](memory_allocator_strategy.md)
