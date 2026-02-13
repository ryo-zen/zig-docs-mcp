# Error Handling Patterns - Practical Guide

This guide focuses on **how to write** error handling code in Zig, not the theory.

📘 **Policy and architecture companion:** [Error Handling Playbook](error_handling_playbook.md)
📚 **Runnable policy tests:** `zig_docs_std/Examples/error_handling_playbook.tests.zig`

## Table of Contents
- [Capture Patterns](#capture-patterns)
- [defer vs errdefer](#defer-vs-errdefer)
- [Common Patterns](#common-patterns)
- [Multi-Step Cleanup](#multi-step-cleanup)
- [Optional Error Handling](#optional-error-handling)

---

## Capture Patterns

Understanding capture syntax is critical for correct error handling in Zig.

### Read-Only Capture (const pointer)

When you capture with `|*val|`, you get a **const pointer**:

```zig
if (getOptional()) |*val| {
    // val is *const T - can read, cannot modify
    std.debug.print("Value: {}", .{val.field});  // ✅ OK
    val.deinit();  // ❌ ERROR: cannot call mutating method on const pointer
}
```

**Use when:** You only need to read the value, not modify it.

---

### Mutable Capture (value → var)

When you capture with `|val|`, you get a **value** that you can make mutable:

```zig
if (getOptional()) |val| {
    var mutable = val;  // ✅ Now can modify
    mutable.deinit();   // ✅ OK - can call mutating methods
}
```

**Use when:** You need to modify the value or call methods that take `*T`.

---

### Error Capture

Capturing errors is always by value:

```zig
reader.readAll() catch |err| {
    // err is the error value (by value, not pointer)
    if (err == error.EndOfStream) return;
    std.debug.print("Error: {}\n", .{err});
    return err;  // Propagate other errors
};
```

---

### Capture Patterns Reference Table

| Pattern | Syntax | Type | Can Modify? | Use Case |
|---------|--------|------|-------------|----------|
| Const pointer | `\|*val\|` | `*const T` | ❌ No | Read-only access |
| Value (can make mutable) | `\|val\|` | `T` | ✅ Yes (via `var`) | Need to modify or call mutating methods |
| Error | `catch \|err\|` | `error` | N/A | Handle specific errors |

---

### Common Mistake: Const Pointer in errdefer

This is the most common error pattern:

```zig
// ❌ BAD: Creates *const pointer
errdefer if (self.partial_result) |*result| {
    result.deinit();  // ERROR: cannot modify *const
}

// ✅ GOOD: Capture value, assign to var
errdefer if (self.partial_result) |val| {
    var result = val;  // Make mutable
    result.deinit();   // OK
}
```

**Why it happens:**
- `|*result|` captures a const pointer for safety
- `deinit()` usually takes `*T` (mutable pointer), not `*const T`
- Solution: capture by value, then assign to `var`

---

## defer vs errdefer

### defer - Always Executes

`defer` runs at scope exit, **regardless** of whether an error occurred:

```zig
fn example() !void {
    const ptr = try allocator.create(Thing);
    defer allocator.destroy(ptr);  // ✅ Runs on both success AND error

    try doSomething(ptr);  // Even if this errors, defer runs
}
```

**Use when:** Resource must be cleaned up in all cases.

---

### errdefer - Only on Error

`errdefer` runs **only if** a subsequent error occurs:

```zig
fn example() !void {
    const ptr = try allocator.create(Thing);
    errdefer allocator.destroy(ptr);  // ✅ Only runs if error after this point

    try list.append(ptr);  // If THIS fails, errdefer cleans up

    // If we get here (no error), errdefer does NOT run
    // Caller now owns ptr
}
```

**Use when:** Resource ownership transfers on success.

---

### defer vs errdefer Comparison

```zig
fn setupResource() !Resource {
    // Scenario 1: Always cleanup (defer)
    const temp = try allocator.alloc(u8, 1024);
    defer allocator.free(temp);  // Always freed, even on success

    // Scenario 2: Cleanup only on error (errdefer)
    const resource = try allocator.create(Resource);
    errdefer allocator.destroy(resource);  // Only if error below

    try resource.init();  // If this fails, errdefer cleans up

    return resource;  // Success: errdefer does NOT run, caller owns resource
}
```

---

### Multiple defers - Reverse Order

Defers execute in **reverse order**:

```zig
fn example() void {
    defer std.debug.print("1\n", .{});
    defer std.debug.print("2\n", .{});
    defer std.debug.print("3\n", .{});
}
// Prints: 3, 2, 1
```

This is like a **stack** - last defer added runs first.

---

## Common Patterns

### Pattern 1: Loop Until EOF

Reading until end-of-stream is a fundamental pattern:

```zig
while (true) {
    const line = reader.readUntilDelimiter('\n') catch |err| {
  if (err == error.EndOfStream) break;  // ✅ Expected - exit loop
  return err;  // ❌ Unexpected - propagate
    };

    // Process line...
}
```

**Why this works:**
- `EndOfStream` is expected when file ends
- Other errors are unexpected and should propagate
- Loop continues until EOF

---

### Pattern 2: Try Multiple Approaches

Sometimes you want to try something, and fall back if it fails:

```zig
const value = parseAsInt(input) catch |err| blk: {
    if (err == error.InvalidFormat) {
  // Try parsing as float instead
  const float_val = try parseAsFloat(input);
  break :blk @as(i32, @intFromFloat(float_val));
    }
    return err;  // Other errors propagate
};
```

**Key points:**
- Named block (`blk:`) for breaking with a value
- Handle specific error, propagate others
- Labeled break returns value from catch block

---

### Pattern 3: Optional Cleanup

Clean up only if something was partially initialized:

```zig
var partial: ?Thing = null;
errdefer if (partial) |val| {
    var thing = val;  // ✅ Value capture, make mutable
    thing.deinit();
};

partial = try createThing();  // If this succeeds...
try partial.?.connect();      // ...but THIS fails, errdefer cleans up
```

**Why optional?**
- `partial` starts as `null`
- If `createThing()` fails, nothing to clean up
- If `createThing()` succeeds but `connect()` fails, need cleanup

---

### Pattern 4: Accumulate Errors

Sometimes you want to try multiple operations and keep track of what failed:

```zig
const Result = struct { succeeded: usize, failed: usize };

fn processAll(items: []Item) Result {
    var succeeded: usize = 0;
    var failed: usize = 0;

    for (items) |item| {
  item.process() catch {
      failed += 1;
      continue;  // Don't propagate, just count
  };
  succeeded += 1;
    }

    return .{ .succeeded = succeeded, .failed = failed };
}
```

---

### Pattern 5: Wrap Errors with Context

Add context when propagating errors:

```zig
fn loadConfig(path: []const u8) !Config {
    const file = std.Io.File.open(io, path, .{}) catch |err| {
  std.debug.print("Failed to open config at '{s}': {}\n", .{path, err});
  return err;
    };
    defer file.close(io);

    // ... parse config ...
}
```

---

## Multi-Step Cleanup

When building complex resources in multiple steps:

### Pattern: Progressive errdefer

Each step adds its own cleanup:

```zig
fn setupServer(allocator: Allocator, io: *Io) !Server {
    // Step 1: Allocate buffer
    const buffer = try allocator.alloc(u8, 4096);
    errdefer allocator.free(buffer);  // Cleanup if steps 2+ fail

    // Step 2: Create socket
    const socket = try net.Socket.create(io, .ipv4, .stream);
    errdefer socket.close(io);  // Cleanup if steps 3+ fail

    // Step 3: Bind and listen
    try socket.bind(address);
    try socket.listen(128);

    // Success: return all resources, errdefers don't run
    return Server{ .socket = socket, .buffer = buffer };
}
```

**How it works:**
- Each `errdefer` only runs if a **subsequent** error occurs
- On success, none of the errdefers run
- Caller receives fully initialized server and owns all resources

---

### Pattern: Init + errdefer Pattern

Common in struct initialization:

```zig
const Database = struct {
    connection: Connection,
    cache: Cache,

    fn init(allocator: Allocator) !Database {
  var self: Database = undefined;

  // Step 1
  self.connection = try Connection.init(allocator);
  errdefer self.connection.deinit();

  // Step 2
  self.cache = try Cache.init(allocator);
  errdefer self.cache.deinit();

  return self;
    }

    fn deinit(self: *Database) void {
  self.cache.deinit();
  self.connection.deinit();
    }
};
```

---

## Optional Error Handling

### Pattern: Optional with errdefer

Cleaning up optional fields that might be initialized:

```zig
const Parser = struct {
    partial_result: ?Result = null,
    temp_buffer: ?[]u8 = null,

    fn parse(self: *Parser, allocator: Allocator) !Result {
  // Cleanup any partial state on error
  errdefer {
      if (self.partial_result) |val| {
          var result = val;  // Value capture, make mutable
          result.deinit();
      }
      if (self.temp_buffer) |buf| {
          allocator.free(buf);  // No need for var (free takes []u8)
      }
  }

  // ... parsing that might fail at any point ...
    }
};
```

---

### Pattern: Defer Block for Multiple Cleanups

Use a defer block for multiple cleanup operations:

```zig
fn complexOperation(allocator: Allocator) !Result {
    var resource1: ?Resource1 = null;
    var resource2: ?Resource2 = null;
    var resource3: ?Resource3 = null;

    errdefer {
  // Single defer block for all cleanup
  if (resource1) |r| { var x = r; x.deinit(); }
  if (resource2) |r| { var x = r; x.deinit(); }
  if (resource3) |r| { var x = r; x.deinit(); }
    }

    resource1 = try create1(allocator);
    resource2 = try create2(allocator);
    resource3 = try create3(allocator);

    return Result{
  .r1 = resource1.?,
  .r2 = resource2.?,
  .r3 = resource3.?,
    };
}
```

---

## Error Union Unwrapping

### Pattern: Unwrap with default

```zig
const value = getValue() catch default_value;
```

### Pattern: Unwrap or unreachable

```zig
// Only when error is PROVABLY impossible
const value = getValue() catch unreachable;
```

**⚠️ Warning:** Only use `catch unreachable` when you're absolutely certain the error cannot occur. If you're wrong, it will crash at runtime.

---

## See Also

- [common_errors.md](common_errors.md) - Error message solutions
- [errors.md](errors.md) - Error handling language reference
- [defer.md](defer.md) - Defer statement details
- [memory_patterns.md](memory_patterns.md) - Memory management patterns
