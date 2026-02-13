# std.Io.SelectUnion

## Quick Start

### Generating Union from Future Struct

```zig
const std = @import("std");

// Define operations as Future pointers in a struct
const Operations = struct {
    network: *std.Io.Future([]const u8),
    database: *std.Io.Future(QueryResult),
    cache: *std.Io.Future(?CachedValue),
};

// SelectUnion automatically generates this union:
// union(enum) {
//     network: []const u8,
//     database: QueryResult,
//     cache: ?CachedValue,
// }
const ResultUnion = std.Io.SelectUnion(Operations);

pub fn useSelectUnion() !void {
    var futures: Operations = .{
  .network = &network_future,
  .database = &db_future,
  .cache = &cache_future,
    };

    var buffer: [3]ResultUnion = undefined;
    var sel = std.Io.Select(ResultUnion).init(io, &buffer);

    // Use with Select...
}
```

### Pattern: From Futures to Union

```zig
const std = @import("std");

// Step 1: Define struct of Future pointers
const Futures = struct {
    primary_server: *std.Io.Future(!Response),
    backup_server: *std.Io.Future(!Response),
};

// Step 2: Generate union automatically
const ServerResults = std.Io.SelectUnion(Futures);
// Equivalent to:
// union(enum) {
//     primary_server: !Response,
//     backup_server: !Response,
// }

// Step 3: Use with Select
pub fn selectFromFutures(futures: Futures, io: std.Io) !Response {
    var buffer: [2]ServerResults = undefined;
    var sel = std.Io.Select(ServerResults).init(io, &buffer);

    sel.async(.primary_server, waitForFuture, .{futures.primary_server});
    sel.async(.backup_server, waitForFuture, .{futures.backup_server});

    const first = try sel.await();
    sel.cancel();

    return switch (first) {
  inline else => |result| try result,
    };
}
```

⚠️ **Critical**: `SelectUnion` is a compile-time metaprogramming helper. It doesn't create futures—it generates the union type needed for `Select()` based on existing Future definitions.

---

## Overview

`std.Io.SelectUnion(S)` is a compile-time function that transforms a struct type `S` (where each field is a `*Future(T)` pointer) into a tagged union type with matching field names but unwrapped result types. This automates boilerplate when using `Select` with multiple futures of different result types.

**Key Characteristics:**
- **Metaprogramming**: Operates at compile time using `@typeInfo` introspection
- **Type Transformation**: Struct of future pointers → Union of result types
- **Field Preservation**: Keeps the same field names, extracts future result types
- **Zero Runtime Cost**: Pure compile-time type generation

**When to use:**
- You have multiple `Future` instances with different result types
- You want to race those futures using `Select()`
- You want to avoid manually writing the union definition

**When NOT to use:**
- Futures all have the same result type (just use `union(enum) { a: T, b: T }` directly)
- Not using `Select` at all
- Union structure doesn't match 1:1 with futures

## Parameters

`S: type`

A struct type where **each field** is a pointer to a `Future`. The struct describes the set of operations/futures you want to select from.

**Requirements:**
- `S` must be a struct type
- Each field must be `*std.Io.Future(T)` for some type `T`
- Field names will become union variant names
- Field types' `Future` result types will become union field types

**Example:**
```zig
const MyFutures = struct {
    task_a: *std.Io.Future(u32),
    task_b: *std.Io.Future([]const u8),
    task_c: *std.Io.Future(!Response),
};

const MyUnion = std.Io.SelectUnion(MyFutures);
// Generates:
// union(enum) {
//     task_a: u32,
//     task_b: []const u8,
//     task_c: !Response,
// }
```

## Return Value

Returns a tagged union type (union with enum tag) where:
- Each union field name matches the corresponding struct field name
- Each union field type is the result type of the corresponding `Future`

**Generated Union Structure:**
```zig
union(enum) {
    field1: Future1_ResultType,
    field2: Future2_ResultType,
    ...
}
```

## Implementation Details

### Source Code Walkthrough

```zig
pub fn SelectUnion(S: type) type {
    const struct_fields = @typeInfo(S).@"struct".fields;
    // Get compile-time struct field info

    var names: [struct_fields.len][]const u8 = undefined;
    var types: [struct_fields.len]type = undefined;
    // Prepare arrays for union field names and types

    for (struct_fields, &names, &types) |struct_field, *union_field_name, *UnionFieldType| {
  const FieldFuture = @typeInfo(struct_field.type).pointer.child;
  // Unwrap *Future to get Future

  union_field_name.* = struct_field.name;
  // Preserve field name

  UnionFieldType.* = @FieldType(FieldFuture, "result");
  // Extract Future's result type
    }

    return @Union(.auto, std.meta.FieldEnum(S), &names, &types, &@splat(.{}));
    // Construct tagged union at compile time
}
```

**Key Steps:**
1. Introspect struct fields using `@typeInfo`
2. For each field, unwrap `*Future(T)` to get `T`
3. Build union with same field names but unwrapped types
4. Return generated union type

## Usage Patterns

### Pattern 1: Direct Future-to-Union

```zig
const std = @import("std");

const FutureSet = struct {
    network: *std.Io.Future([]const u8),
    timer: *std.Io.Future(void),
};

const Results = std.Io.SelectUnion(FutureSet);

pub fn raceWithTimeout(
    network_future: *std.Io.Future([]const u8),
    timer_future: *std.Io.Future(void),
    io: std.Io
) ![]const u8 {
    const futures = FutureSet{ .network = network_future, .timer = timer_future };

    var buffer: [2]Results = undefined;
    var sel = std.Io.Select(Results).init(io, &buffer);

    sel.async(.network, awaitFuture, .{futures.network});
    sel.async(.timer, awaitFuture, .{futures.timer});

    const first = try sel.await();
    sel.cancel();

    return switch (first) {
  .network => |data| data,
  .timer => error.Timeout,
    };
}
```

### Pattern 2: Multiple Heterogeneous Operations

```zig
const std = @import("std");

const TaskFutures = struct {
    fetch_user: *std.Io.Future(!User),
    fetch_posts: *std.Io.Future(![]Post),
    check_cache: *std.Io.Future(?CacheEntry),
};

const TaskResults = std.Io.SelectUnion(TaskFutures);

pub fn loadDashboard(futures: TaskFutures, io: std.Io) !void {
    var buffer: [3]TaskResults = undefined;
    var sel = std.Io.Select(TaskResults).init(io, &buffer);

    sel.async(.fetch_user, waitForUser, .{futures.fetch_user});
    sel.async(.fetch_posts, waitForPosts, .{futures.fetch_posts});
    sel.async(.check_cache, waitForCache, .{futures.check_cache});

    // Process results as they complete
    const first = try sel.await();
    switch (first) {
  .fetch_user => |user_result| handleUser(try user_result),
  .fetch_posts => |posts_result| handlePosts(try posts_result),
  .check_cache => |cache| if (cache) |entry| handleCache(entry),
    }
}
```

### Pattern 3: Avoiding Manual Union Boilerplate

```zig
const std = @import("std");

// ❌ Manual approach (tedious):
const ManualUnion = union(enum) {
    op1: !Data,
    op2: !OtherData,
    op3: void,
};

// ✅ Automated approach:
const Ops = struct {
    op1: *std.Io.Future(!Data),
    op2: *std.Io.Future(!OtherData),
    op3: *std.Io.Future(void),
};
const AutoUnion = std.Io.SelectUnion(Ops);
// Generates the same union automatically
```

## Relationship to Select

`SelectUnion` is designed specifically to complement `Select()`. The workflow is:

1. **Define Future Types**: Create a struct describing your futures
2. **Generate Union**: Use `SelectUnion` to create the union type
3. **Create Select**: Use `Select(GeneratedUnion)` to race operations
4. **Spawn Tasks**: Use `select.async()` with field names from original struct

**Example Flow:**
```zig
// 1. Define futures
const Ops = struct {
    task_a: *std.Io.Future(u32),
    task_b: *std.Io.Future([]const u8),
};

// 2. Generate union
const Results = std.Io.SelectUnion(Ops);

// 3. Create select
var buffer: [2]Results = undefined;
var sel = std.Io.Select(Results).init(io, &buffer);

// 4. Spawn tasks
sel.async(.task_a, computeNumber, .{io});
sel.async(.task_b, fetchString, .{io});
```

## Compile-Time Guarantees

- **Type Safety**: Field types are extracted from actual `Future` definitions
- **Name Consistency**: Union fields guaranteed to match struct field names
- **Error Propagation**: Error types in futures (e.g., `!T`) are preserved in union
- **No Runtime Overhead**: Entire transformation happens at compile time

## Debug Checklist

- ✅ **Struct Fields Are Future Pointers**: Each field is `*Future(T)`, not `Future(T)` or other types
- ✅ **Consistent Naming**: Struct field names match what you'll use in `select.async(.field, ...)`
- ✅ **Handle All Variants**: When switching on results, cover all possible union tags

## See Also

- `std.Io.Select` - Uses unions generated by SelectUnion for racing operations
- `std.Io.Future` - The future type that SelectUnion unwraps
- `@typeInfo` - Zig builtin for compile-time type introspection
- `@Union` - Zig builtin for constructing union types
