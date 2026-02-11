# Memory

Zig performs no implicit memory allocations. There is no hidden runtime, no garbage collector, and no default allocator. This manual management allows Zig to be used in real-time software, kernels, and embedded devices.

As a consequence, a Zig programmer must always be able to answer: **[Where are the bytes?](#where-are-the-bytes)**

📚 **[See Memory Patterns & Examples](../zig_docs_std/Examples/test_memory_patterns.zig)** - Complete working examples of all patterns discussed in this guide

📚 **[See Memory Safety Examples](../zig_docs_std/Examples/test_memory_safety.zig)** - Tests demonstrating null safety, leak detection, and bounds checking

📚 **[See Allocator Strategy Tests](../zig_docs_std/Examples/memory_allocator_strategy.tests.zig)** - Practical allocator selection patterns and constraints

📚 **[See OOM Handling Tests](../zig_docs_std/Examples/memory_oom_handling.tests.zig)** - Deterministic `OutOfMemory` error-path validation with failing allocators

📚 **[See Ownership Contract Tests](../zig_docs_std/Examples/memory_ownership_contract.tests.zig)** - Caller ownership, cleanup, and `deinit` contract patterns

📘 **[Allocator Strategy Guide](memory_allocator_strategy.md)** - Decision matrix, ownership checklist, and anti-patterns

## Overview

This guide focuses on practical allocation strategy, ownership contracts, and failure-safe cleanup patterns for production Zig code.

If you remember one rule, use this: every allocation site should have an explicit ownership decision and cleanup path.

## Quick Reference

| Allocator | Use When | Performance | Memory Overhead | Debug Features |
|-----------|----------|-------------|-----------------|----------------|
| `GeneralPurposeAllocator` | Most applications | Good | Medium | ✅ Leak detection, double-free, use-after-free |
| `ArenaAllocator` | Batch deallocation (request handlers, frames) | Excellent | Low | ❌ (uses child allocator's) |
| `FixedBufferAllocator` | Known max memory, embedded systems | Fastest | None | ❌ Fails on overflow |
| `c_allocator` | Linking with C libraries | Variable | Variable | ❌ (depends on libc) |
| `page_allocator` | Large allocations, OS pages | Good for large | High (page-aligned) | ❌ |
| `testing.allocator` | Unit tests | Good | Medium | ✅ Automatic leak detection |

## Allocator Selection Flow

Use this in order:

1. Need C ABI-compatible allocation behavior? Use `c_allocator`.
2. Need strict memory budget/no heap? Use `FixedBufferAllocator`.
3. Have phase-based lifetime (request/frame/job) with bulk cleanup? Use `ArenaAllocator`.
4. Need general app allocator with safety diagnostics? Use `GeneralPurposeAllocator`.
5. Need very large/page-granular allocations? Consider `page_allocator`.

When unsure, start with `GeneralPurposeAllocator`, then optimize with measurement.

## Allocators

In C, `malloc` is a global default. In Zig, functions that need to allocate memory accept an `Allocator` parameter.

### Basic Usage

The standard library provides several allocators. The `std.mem.Allocator` interface is used to pass them around.

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

test "using an allocator" {
    // 1. Create an allocator (FixedBufferAllocator in this example)
    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // 2. Pass it to functions
    const result = try concat(allocator, "foo", "bar");
    
    try std.testing.expect(std.mem.eql(u8, "foobar", result));
}

// Function accepting a generic Allocator interface
fn concat(allocator: Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}
```

## Choosing an Allocator

Different problems require different memory strategies. Use this guide to choose the right tool:

### 1. General Purpose
For most applications, use `std.heap.GeneralPurposeAllocator`.
*   **Debug Mode:** Automatically detects memory leaks, double-frees, and use-after-frees.
*   **Release Mode:** Becomes a high-performance allocator (backing off to `smp_allocator` or similar).

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// Check for leaks at program exit (returns true if leak detected)
defer _ = gpa.deinit();
const allocator = gpa.allocator();
```

------

### 2. Linking with C (libc)
If your project links against `libc`, use `std.heap.c_allocator`. This wraps `malloc`/`free`, allowing seamless integration with C libraries.

------

### 3. Bounded Memory (Fixed Buffer)
If you know the maximum memory usage at **comptime** or strictly bounded runtime, use `std.heap.FixedBufferAllocator`.
*   **Performance:** Extremely fast (just increments a pointer).
*   **Safety:** Fails with `OutOfMemory` if the buffer is full.
*   **Use case:** Embedded systems, request buffers, short-lived stack allocations.

------

### 4. Arena (Batch Deallocation)
If you have a cycle (like a request handler or a game frame) where you allocate many items and free them all at once, use `std.heap.ArenaAllocator`.
*   **Mechanism:** Wraps a child allocator. Allocations are fast.
*   **Deallocation:** `arena.deinit()` frees *everything* at once. You don't need to free individual objects.

```zig
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // Free everything in the arena when scope exits
    defer arena.deinit();
    const allocator = arena.allocator();

    // No need to free 'ptr' manually!
    const ptr = try allocator.create(i32);
    _ = ptr;
}
```

------

### 5. Testing
*   **`std.testing.allocator`**: A GPA preset for tests. Detects leaks automatically.
*   **`std.testing.FailingAllocator`**: Wraps another allocator and artificially fails after `N` allocations. Use this to test your `error.OutOfMemory` handling logic.

## Common Pitfalls

### ❌ Forgetting to free memory
```zig
// BAD: Memory leak
const ptr = try allocator.create(i32);
// Function ends, ptr is lost forever
```

**Fix:** Use `defer` immediately after allocation:
```zig
// GOOD: Automatic cleanup
const ptr = try allocator.create(i32);
defer allocator.destroy(ptr);
ptr.* = 42;
```

------

### ❌ Returning stack memory
```zig
// BAD: Dangling pointer
fn makeString() []u8 {
    var buffer: [10]u8 = undefined;
    return buffer[0..]; // ⚠️ Points to dead stack frame
}
```

**Fix:** Allocate on heap or use caller-provided buffer:
```zig
// GOOD: Heap allocation
fn makeString(allocator: Allocator) ![]u8 {
    return allocator.dupe(u8, "hello");
}

// GOOD: Caller-provided buffer
fn makeString(buffer: []u8) []u8 {
    const msg = "hello";
    @memcpy(buffer[0..msg.len], msg);
    return buffer[0..msg.len];
}
```

------

### ❌ Double-freeing with Arena
```zig
// BAD: Unnecessary and wrong
var arena = std.heap.ArenaAllocator.init(child);
defer arena.deinit();

const ptr = try arena.allocator().create(i32);
arena.allocator().destroy(ptr); // ❌ Don't do this
// arena.deinit() will try to free again
```

**Fix:** Let arena handle all deallocation:
```zig
// GOOD: Arena manages everything
var arena = std.heap.ArenaAllocator.init(child);
defer arena.deinit();

const ptr = try arena.allocator().create(i32);
// No manual free needed - arena.deinit() handles it
```

------

### ❌ Using uninitialized memory
```zig
// BAD: Reading undefined memory
var buffer: [100]u8 = undefined;
std.debug.print("{s}\n", .{buffer}); // ⚠️ Garbage data
```

**Fix:** Initialize before use:
```zig
// GOOD: Zero-initialize
var buffer = [_]u8{0} ** 100;
std.debug.print("{s}\n", .{buffer}); // Safe

// GOOD: Explicit initialization
var buffer: [100]u8 = undefined;
@memset(&buffer, 0);
std.debug.print("{s}\n", .{buffer}); // Safe
```

------

### ❌ Forgetting to check allocation errors
```zig
// BAD: Ignoring OutOfMemory
const ptr = allocator.create(i32) catch unreachable;
// ⚠️ What if allocation actually fails?
```

**Fix:** Propagate errors or handle explicitly:
```zig
// GOOD: Propagate to caller
const ptr = try allocator.create(i32);

// GOOD: Explicit handling
const ptr = allocator.create(i32) catch |err| {
    std.debug.print("Allocation failed: {}\n", .{err});
    return err;
};
```

## Where are the bytes?

Zig distinguishes between memory locations explicitly.

### Global Constant Data
String literals and `const` values known at comptime live here. They are immutable.

```zig
test "string literals are const" {
    // This is valid:
    const s: []const u8 = "hello";
    
    // This would be a compile error:
    // var mutable_s: []u8 = "hello"; 
    // Error: types '[]u8' and '*const [5:0]u8' are incompatible
    
    _ = s;
}
```

### Stack
`var` declarations inside functions live on the stack.
*   **Lifetime:** Valid only until the function returns.
*   **Danger:** Never return a pointer to a stack variable.

### Heap
Memory returned by `allocator.alloc` or `allocator.create`.
*   **Lifetime:** Valid until explicitly freed (or the arena is cleared).

## Heap Allocation Failure

Zig treats memory allocation failure as a handleable error (`error.OutOfMemory`), not an immediate crash.

*   **Libraries:** Should always propagate `!Allocator` errors so the caller can decide (crash, retry, or fallback).
*   **Applications:** Can choose to crash (panic) if memory is exhausted, but having the *option* to handle it is critical for high-reliability software (aviation, kernels, medical).

## Memory Safety

Zig prioritizes spatial memory safety and provides tooling for temporal memory safety, though it relies on runtime checks rather than compile-time borrow checking.

### 1. Null Safety
Standard pointers (`*T`) **cannot** be null.
*   **Safe:** `var ptr: *i32` is guaranteed to point to a valid address (if initialized).
*   **Optional:** `var ptr: ?*i32` allows null, but the compiler forces you to unwrap it (e.g., `if (ptr) |p|`) before dereferencing.

### 2. Bounds Checking
Accessing arrays and slices (`[]T`) is checked at runtime in `Debug` and `ReleaseSafe` modes. Buffer overflows result in a safe panic rather than a security vulnerability.

### 3. Debug Tooling (GPA)
The `std.heap.GeneralPurposeAllocator` is not just for allocation; it is a safety tool. In Debug mode, it detects:
*   **Memory Leaks:** Prints a report of un-freed bytes at exit.
*   **Double Free:** Panics if you free the same pointer twice.
*   **Use-After-Free:** Attempts to detect access to freed memory (implementation dependent, usually by scrubbing memory).

### 4. Undefined Memory
In Debug builds, Zig often fills `undefined` memory with `0xaa` bytes. This ensures that logic errors involving uninitialized variables cause immediate, visible crashes (like segfaults) rather than silently corrupting data.

## Unsafe Memory Boundary Checklist

Before any pointer cast, manual copy, sentinel trick, or raw byte reinterpretation:

1. **Alignment:** Is the pointer aligned for the target type?
2. **Bounds:** Is the full accessed range within allocated memory?
3. **Lifetime:** Will the backing allocation outlive all references?
4. **Aliasing:** Are there overlapping mutable references that can race/corrupt?
5. **Sentinel assumptions:** If sentinel-typed, is the sentinel guaranteed at `len`?
6. **Cleanup path:** Is deallocation deterministic on both success and error paths?

If any answer is unclear, encode the assumption with an assertion or redesign API boundaries.

## Debugging Memory Issues

### Finding Memory Leaks with GPA

**Step 1:** Wrap your allocator in GPA
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer {
    const leaked = gpa.deinit();
    if (leaked == .leak) {
        std.debug.print("❌ MEMORY LEAK DETECTED\n", .{});
    }
}
const allocator = gpa.allocator();
```

**Step 2:** Run in Debug mode
```bash
zig build run
# or
zig run src/main.zig
```

**Step 3:** Read the leak report
```
=== LEAK DETECTED ===
Address: 0x7f8a4c000b80
Size: 24 bytes
Allocated at:
  src/main.zig:15:32
  std/mem/Allocator.zig:89:41
```

**Step 4:** Find the missing `defer allocator.free()`
- Search for line 15 in main.zig
- Add `defer allocator.free(ptr);` after the allocation
- Re-run to verify the leak is fixed

------

### Debugging Use-After-Free

GPA can detect some use-after-free bugs by scrubbing freed memory:

```zig
test "detecting use-after-free" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ptr = try allocator.create(i32);
    ptr.* = 42;
    allocator.destroy(ptr);

    // ❌ This may panic in Debug mode:
    // const val = ptr.*; // Use-after-free
}
```

**Tip:** In Debug builds, GPA often fills freed memory with `0xaa`, making use-after-free bugs more visible.

------

### Debugging Double-Free

GPA immediately panics on double-free:

```zig
test "detecting double-free" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ptr = try allocator.create(i32);
    allocator.destroy(ptr);
    // allocator.destroy(ptr); // ❌ Panic: double-free detected
}
```

**Output:**
```
thread X panic: Double free detected
```

## Lifetime and Ownership

Because there is no garbage collection, documentation and conventions define ownership:

*   **"Caller owns memory":** The function returns a pointer, and you (the caller) must free it.
*   **"Arena managed":** The object lives in an arena and doesn't need individual freeing.
*   **`std.ArrayList`:** The list owns the items array. When you call `list.deinit(allocator)`, the items array is freed (but complex items *inside* the list might need their own cleanup first).

### Ownership Contract Template

Use this wording pattern in public APIs:

- **Allocation source:** "Allocated with caller-provided `allocator`."
- **Owner after return:** "Caller owns returned memory."
- **Cleanup API:** "Caller must call `deinit(allocator)`" or "caller must `allocator.free(...)`."
- **Lifetime guarantees:** "Valid until X is deinitialized/reset."
- **Error behavior:** "On error, no ownership is transferred" (or explicitly what is transferred).

Example contract:

```zig
/// Allocates and returns UTF-8 bytes for `input`.
/// Owner: caller.
/// Cleanup: caller must `allocator.free(result)`.
/// On error: no allocation is leaked and no ownership is transferred.
pub fn transform(allocator: Allocator, input: []const u8) ![]u8 { ... }
```

## Real-World Patterns

### HTTP Request Handler Pattern
```zig
fn handleRequest(gpa: Allocator, request: Request) !Response {
    // Arena for request-scoped allocations
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit(); // Free everything at once

    const allocator = arena.allocator();

    // Parse JSON, build strings, etc. - all arena-allocated
    const body = try parseJson(allocator, request.body);
    const response = try buildResponse(allocator, body);

    // Response is copied before arena.deinit()
    return response.clone(gpa);
}

fn parseJson(allocator: Allocator, data: []const u8) !ParsedData {
    // All temp allocations use arena - no manual free needed
    const parsed = try allocator.alloc(u8, data.len);
    @memcpy(parsed, data);
    return ParsedData{ .content = parsed };
}
```

------

### Game Frame Pattern
```zig
fn gameLoop(gpa: Allocator) !void {
    var frame_arena = std.heap.ArenaAllocator.init(gpa);
    defer frame_arena.deinit();

    while (game.running) {
        // Reset arena but keep capacity for next frame
        defer _ = frame_arena.reset(.retain_capacity);

        const allocator = frame_arena.allocator();
        const entities = try loadEntities(allocator);
        try renderFrame(allocator, entities);
        // All frame memory freed at loop end
    }
}
```

------

### Embedded System Pattern (Fixed Buffer)
```zig
fn processCommand(command: []const u8) !void {
    // Stack buffer - no heap allocation
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Parse and process within fixed budget
    const parsed = try parseCommand(allocator, command);
    try executeCommand(parsed);
    // Buffer automatically reclaimed when function returns
}
```

------

### Library Function Pattern (Caller Allocates)
```zig
// Library API: caller provides allocator
pub fn parseConfig(allocator: Allocator, path: []const u8) !Config {
    const file_content = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
    defer allocator.free(file_content);

    // Parse and return owned data
    var config = Config{};
    config.entries = try parseEntries(allocator, file_content);
    return config; // Caller must call config.deinit(allocator) later
}

pub const Config = struct {
    entries: []Entry,

    pub fn deinit(self: *Config, allocator: Allocator) void {
        allocator.free(self.entries);
    }
};
```

------

### Testing Pattern with Multiple Allocations
```zig
test "complex data structure" {
    const allocator = std.testing.allocator;

    // Create list (Zig 0.16 API)
    var list: std.ArrayList(i32) = .{};
    defer list.deinit(allocator);

    // Allocate separate items
    const item1 = try allocator.create(i32);
    defer allocator.destroy(item1);

    const item2 = try allocator.create(i32);
    defer allocator.destroy(item2);

    // Use items
    item1.* = 10;
    item2.* = 20;
    try list.append(allocator, item1.*);
    try list.append(allocator, item2.*);

    // std.testing.allocator will catch any leaks
}
```

## When NOT to Use Each Allocator

### ❌ Don't use ArenaAllocator for:
- **Long-running services without clear cleanup points** - Memory will accumulate indefinitely
- **When individual deallocations are needed** - Can't free specific items, only everything
- **Memory-constrained environments** - Can't reclaim memory until full deinit
- **Example:** A daemon process that runs for days/weeks without restart points

### ❌ Don't use FixedBufferAllocator for:
- **Unbounded user input** - Buffer overflow will cause `error.OutOfMemory`
- **Recursive algorithms with unknown depth** - Stack frames may exceed buffer
- **Anything that might exceed buffer size unpredictably** - Better to fail gracefully with GPA
- **Example:** Parsing arbitrary-size JSON from untrusted sources

### ❌ Don't use page_allocator for:
- **Small allocations** - Wastes memory due to page alignment (typically 4KB minimum)
- **Frequent allocations** - Every allocation is a syscall (expensive)
- **Example:** Allocating hundreds of small structs individually

### ❌ Don't use GeneralPurposeAllocator for:
- **Embedded systems with tiny RAM** - Debug features add overhead
- **Hard real-time systems** - Lock contention and debug checks add latency
- **When linking with C libraries that use malloc** - Use `c_allocator` instead for interop
- **Example:** Microcontroller with 32KB RAM running a control loop
