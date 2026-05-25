# std.Io.Select

## Quick Start

### Racing Multiple Operations

```zig
const std = @import("std");

const Result = union(enum) {
    network: []const u8,
    timeout: void,
};

pub fn raceNetworkAndTimeout(io: std.Io) !Result {
    var buffer: [2]Result = undefined;
    var select_obj = std.Io.Select(Result).init(io, &buffer);

    // Spawn network fetch
    select_obj.async(.network, fetchData, .{io});

    // Spawn timeout task
    select_obj.async(.timeout, sleepMillis, .{io, 1000});

    // Wait for first to complete
    const first = try select_obj.await();

    // Cancel remaining tasks
    select_obj.cancel();

    return first;
}
```

### First-Wins Pattern

```zig
const std = @import("std");

const ServerResponse = union(enum) {
    primary: []const u8,
    backup: []const u8,
};

pub fn queryWithFallback(io: std.Io) ![]const u8 {
    var buffer: [2]ServerResponse = undefined;
    var select_obj = std.Io.Select(ServerResponse).init(io, &buffer);

    select_obj.async(.primary, queryServer, .{io, "primary.example.com"});
    select_obj.async(.backup, queryServer, .{io, "backup.example.com"});

    const first = try select_obj.await();

    // Cancel the slower server
    select_obj.cancel();

    return switch (first) {
  .primary => |data| data,
  .backup => |data| data,
    };
}
```

⚠️ **Critical**: Always call `cancel()` to clean up remaining tasks. Failing to cancel leaves orphaned tasks consuming resources.

---

## Overview

`std.Io.Select(U)` is a structured concurrency primitive for racing multiple asynchronous operations and handling the first completion. It's similar to Go's `select` statement or JavaScript's `Promise.race()`, but with Zig's type safety and explicit resource management.

**Key Characteristics:**
- **Generic Result Type**: `U` must be a tagged union (enum union) with each field representing one operation type
- **Ownership**: Select owns all spawned tasks via a `Group`, ensuring cleanup
- **First-Wins Semantics**: `await()` returns the first completed result
- **Explicit Cancellation**: Remaining tasks must be explicitly cancelled via `cancel()`
- **Fixed Capacity**: Backed by a caller-provided result buffer

**When to use:**
- Racing multiple network requests (primary/backup servers)
- Implementing timeouts (race operation vs. timer)
- First-successful pattern (try multiple strategies, use first success)
- Concurrent probing (check multiple resources, return first available)

**When NOT to use:**
- Need all results (use `Group.wait()` instead)
- Single operation (no need for select)
- Dynamic/unbounded number of tasks (select has fixed buffer capacity)

## Parameters

`U: type`

The result union type. Must be a tagged union where each field name corresponds to an operation type and the field type is that operation's result type.

**Example:**
```zig
const MyResult = union(enum) {
    network_fetch: []const u8,
    cache_lookup: ?CachedData,
    timeout: void,
};

var select_obj = std.Io.Select(MyResult).init(...);
```

## Fields

`io: Io`

The I/O context used to spawn and manage tasks.

------

`group: Group`

The task group owning all spawned operations. Ensures tasks are properly tracked and can be cancelled.

------

`queue: Queue(U)`

Internal queue collecting completed results from spawned tasks. `await()` pulls from this queue.

------

`outstanding: usize`

Counter tracking the number of tasks still running. Decrements as tasks complete or are cancelled.

## Types

### `Field`

Enum representing the possible field names of the union `U`. Used by `async()` to tag which operation is being launched.

**Example:**
```zig
const Result = union(enum) {
    op1: u32,
    op2: []const u8,
};

// Field is an enum: enum { op1, op2 }
```

## Initialization

### `pub fn init(io: Io, buffer: []U) Select(U)`

Creates a new Select instance backed by the provided result buffer.

**Parameters:**
- `io`: The I/O context for task management
- `buffer`: Result buffer. Size determines maximum concurrent operations.

**Returns:** Initialized `Select(U)`

**Example:**
```zig
var result_buffer: [4]MyResult = undefined;
var select_obj = std.Io.Select(MyResult).init(io, &result_buffer);
```

## Core Functions

### `pub fn async(s: *Select(U), comptime field: Field, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function))) void`

Spawns an asynchronous operation owned by the select. The function result is automatically wrapped in a union value tagged with `field`.

**Parameters:**
- `field`: Compile-time field name from `U` (e.g., `.network_fetch`)
- `function`: Function to call asynchronously. Return type must match `U`'s field type.
- `args`: Tuple of arguments to pass to `function`

**Behavior:**
- Spawns a task in the select's group
- When `function` completes, its result is enqueued as `U{ .field = result }`
- Task is owned by select until `cancel()` or all tasks complete

**Example:**
```zig
select_obj.async(.network, fetchFromServer, .{io, "example.com"});
select_obj.async(.cache, lookupCache, .{io, "key123"});
```

------

### `pub fn await(s: *Select(U)) Cancelable!U`

Blocks until the next task completes and returns its result.

**Returns:** The next completed result from the queue

**Errors:**
- `error.Canceled`: The current task was cancelled while waiting

**Behavior:**
- Blocks if no results are ready
- Returns immediately if a result is already queued
- Can be called multiple times to get successive results

**Example:**
```zig
const first = try select_obj.await();
std.debug.print("First completion: {}\n", .{first});

const second = try select_obj.await();
std.debug.print("Second completion: {}\n", .{second});
```

------

### `pub fn cancel(s: *Select(U)) void`

Requests cancellation on all remaining tasks owned by the select. Equivalent to calling `Group.cancel()` on the internal group.

**Behavior:**
- Marks all outstanding tasks for cancellation
- Tasks may complete normally if they were in uncancellable sections
- Does not block; cancellation is asynchronous

**Use case:** Cleanup after getting the first result, or during shutdown.

**Example:**
```zig
const winner = try select_obj.await();
select_obj.cancel(); // Stop all remaining tasks

processResult(winner);
```

## Type Alias

### `Union`

Alias for `SelectUnion(S)`, which generates the union type corresponding to the struct of futures passed to a select-style operation. (This is an advanced pattern; see `SelectUnion` documentation for details.)

## Usage Patterns

### Timeout Pattern

```zig
const std = @import("std");

const Result = union(enum) {
    operation: Data,
    timeout: void,
};

pub fn operationWithTimeout(io: std.Io, timeout_ms: u64) !Data {
    var buffer: [2]Result = undefined;
    var sel = std.Io.Select(Result).init(io, &buffer);

    sel.async(.operation, performSlowOperation, .{io});
    sel.async(.timeout, sleepMillis, .{io, timeout_ms});

    const first = try sel.await();
    sel.cancel();

    return switch (first) {
  .operation => |data| data,
  .timeout => error.Timeout,
    };
}
```

### Load Balancing (First Available Server)

```zig
const std = @import("std");

const ServerResult = union(enum) {
    server1: Response,
    server2: Response,
    server3: Response,
};

pub fn queryFirstResponder(io: std.Io) !Response {
    var buffer: [3]ServerResult = undefined;
    var sel = std.Io.Select(ServerResult).init(io, &buffer);

    sel.async(.server1, queryServer, .{io, "server1.example.com"});
    sel.async(.server2, queryServer, .{io, "server2.example.com"});
    sel.async(.server3, queryServer, .{io, "server3.example.com"});

    const fastest = try sel.await();
    sel.cancel(); // Stop slower servers

    return switch (fastest) {
  inline else => |response| response,
    };
}
```

### Collecting Multiple Results

```zig
const std = @import("std");

const Result = union(enum) {
    task_a: u32,
    task_b: []const u8,
};

pub fn collectBoth(io: std.Io) !struct { u32, []const u8 } {
    var buffer: [2]Result = undefined;
    var sel = std.Io.Select(Result).init(io, &buffer);

    sel.async(.task_a, computeNumber, .{io});
    sel.async(.task_b, fetchString, .{io});

    const first = try sel.await();
    const second = try sel.await();

    // No need to cancel - all tasks completed

    var result_a: ?u32 = null;
    var result_b: ?[]const u8 = null;

    for ([_]Result{ first, second }) |res| {
  switch (res) {
      .task_a => |val| result_a = val,
      .task_b => |val| result_b = val,
  }
    }

    return .{ result_a.?, result_b.? };
}
```

### Resilient Fetch (Retry on Failure)

```zig
const std = @import("std");

const AttemptResult = union(enum) {
    attempt1: !Data,
    attempt2: !Data,
    attempt3: !Data,
};

pub fn fetchWithRetries(io: std.Io) !Data {
    var buffer: [3]AttemptResult = undefined;
    var sel = std.Io.Select(AttemptResult).init(io, &buffer);

    // Launch three concurrent attempts
    sel.async(.attempt1, tryFetch, .{io, "primary"});
    sel.async(.attempt2, tryFetch, .{io, "backup1"});
    sel.async(.attempt3, tryFetch, .{io, "backup2"});

    // Return first successful result
    while (true) {
  const result = try sel.await();

  const maybe_data = switch (result) {
      inline else => |attempt_result| attempt_result,
  };

  if (maybe_data) |data| {
      sel.cancel();
      return data;
  }
    }

    return error.AllAttemptsFailed;
}
```

## Debug Checklist

- ✅ **Cancel Called**: Did you call `cancel()` after getting results?
- ✅ **Buffer Size**: Is the buffer large enough for all concurrent operations?
- ✅ **Union Fields Match**: Does each `.async()` field match a union variant?
- ✅ **Return Types Match**: Do function return types match the corresponding union field types?
- ✅ **Handle All Variants**: Does your `switch` on results cover all possible union tags?

## Performance Tips

1. **Size Buffer Appropriately**: Buffer should match expected number of concurrent operations
2. **Cancel Early**: Stop remaining tasks as soon as you have the result you need
3. **Avoid Blocking `await()`**: If using multiple `await()` calls, ensure tasks can complete
4. **Use Inline Switch**: `switch (result) { inline else => |val| val }` for uniform handling

## See Also

- `std.Io.Group` - For managing task groups without first-wins semantics
- `std.Io.Future` - Individual async operation primitive
- `std.Io.Queue` - The underlying queue type used internally
