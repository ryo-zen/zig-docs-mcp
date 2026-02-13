# std.heap

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all heap allocator features

## Quick Start

### Most Common Patterns

**GeneralPurposeAllocator (Recommended for Development)**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer {
    const deinit_status = gpa.deinit();
    if (deinit_status == .leak) @panic("Memory leak detected!");
}
const allocator = gpa.allocator();

const bytes = try allocator.alloc(u8, 100);
defer allocator.free(bytes);
```

**ArenaAllocator (Bulk Free)**
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit(); // Frees everything at once

const allocator = arena.allocator();
const items = try allocator.alloc(i32, 1000);
// No individual free needed - arena.deinit() frees all
```

**FixedBufferAllocator (Stack Memory)**
```zig
var buffer: [1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

const data = try allocator.alloc(u8, 100);
// No free needed - memory is on stack
```

**page_allocator (Direct OS Pages)**
```zig
const allocator = std.heap.page_allocator;
const large_buffer = try allocator.alloc(u8, 1024 * 1024); // 1 MB
defer allocator.free(large_buffer);
```

**c_allocator (C Interop)**
```zig
const allocator = std.heap.c_allocator;
const ptr = try allocator.create(MyStruct);
defer allocator.destroy(ptr);
```

### Common Operations

| Operation | Method | Example |
|-----------|--------|---------|
| Allocate slice | `alloc(T, n)` | `try allocator.alloc(u8, 100)` |
| Free slice | `free(slice)` | `allocator.free(bytes)` |
| Allocate single | `create(T)` | `try allocator.create(Node)` |
| Free single | `destroy(ptr)` | `allocator.destroy(node)` |
| Reallocate | `realloc(slice, n)` | `try allocator.realloc(bytes, 200)` |
| Duplicate | `dupe(T, slice)` | `try allocator.dupe(u8, "hello")` |

### ⚠️ Critical: Always Free Memory
```zig
// ❌ BAD - Memory leak!
const data = try allocator.alloc(u8, 100);
// Forgot to free!

// ✅ GOOD - Immediate defer
const data = try allocator.alloc(u8, 100);
defer allocator.free(data);

// ✅ ALSO GOOD - Arena pattern (bulk free)
var arena = std.heap.ArenaAllocator.init(base_allocator);
defer arena.deinit(); // Frees everything
```

---

## Overview

`std.heap` provides Zig's memory allocation infrastructure. Unlike languages with garbage collection, Zig gives you explicit control over memory allocation and deallocation. The `Allocator` interface is central to Zig's memory management philosophy.

**Key Characteristics:**
- **Explicit allocation**: No hidden allocations - you control when and how memory is allocated
- **Pluggable allocators**: Single `Allocator` interface works with any backing implementation
- **Safety by default**: GeneralPurposeAllocator detects use-after-free and double-free in debug builds
- **Zero overhead abstractions**: Allocator interface compiles to direct calls
- **Composition**: Allocators can wrap other allocators (logging, thread-safety, debugging)

**When to use std.heap:**
- Every non-trivial Zig program uses allocators
- Dynamic data structures (ArrayList, HashMap, etc.)
- Variable-sized buffers
- Long-lived data that outlives function scope
- Interfacing with C libraries

**Allocator Selection Guide:**
- **Development/Testing**: `GeneralPurposeAllocator` (safety checks)
- **Bulk allocations**: `ArenaAllocator` (free everything at once)
- **Small/predictable sizes**: `FixedBufferAllocator` (stack-based)
- **Production/performance**: `page_allocator` or `c_allocator`
- **C interop**: `c_allocator` (uses malloc/free)

---

## Core Allocators

### GeneralPurposeAllocator

The recommended allocator for development and testing. Provides safety checks including leak detection, double-free detection, and use-after-free detection in debug builds.

**Type:** `std.heap.GeneralPurposeAllocator(config: GeneralPurposeAllocatorConfig)`

**Key Features:**
- **Leak detection**: Reports memory leaks on deinit
- **Double-free detection**: Catches attempts to free the same memory twice
- **Use-after-free detection**: Can catch some use-after-free bugs
- **Thread-safe**: Safe to use from multiple threads
- **Configurable**: Adjust safety vs performance trade-offs

**Configuration Options:**
```zig
pub const GeneralPurposeAllocatorConfig = struct {
    safety: bool = std.debug.runtime_safety,
    thread_safe: bool = true,
    never_unmap: bool = false,
    retain_metadata: bool = false,
    verbose_log: bool = false,
};
```

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    // Default configuration (safety checks enabled)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
  const deinit_status = gpa.deinit();
  if (deinit_status == .leak) {
      std.debug.print("Memory leak detected!\n", .{});
  }
    }
    const allocator = gpa.allocator();

    // Allocate and use memory
    const numbers = try allocator.alloc(i32, 10);
    defer allocator.free(numbers);

    for (numbers, 0..) |*num, i| {
  num.* = @intCast(i * 2);
    }

    std.debug.print("Numbers: {any}\n", .{numbers});
}
```

**Performance:** Slightly slower than raw page_allocator due to safety checks, but essential for development.

**Best for:** Development, testing, and applications where safety is prioritized.

------

### ArenaAllocator

Bulk allocation arena that frees all memory at once. Extremely efficient when you have many small allocations with the same lifetime.

**Type:** `std.heap.ArenaAllocator`

**Key Features:**
- **Bulk deallocation**: Single `deinit()` frees everything
- **No individual frees**: Saves bookkeeping overhead
- **Fast allocation**: Very quick for small allocations
- **Simple lifetime management**: Perfect for request/response patterns

**Typical Pattern:**
```zig
// Setup
var arena = std.heap.ArenaAllocator.init(backing_allocator);
defer arena.deinit(); // Frees ALL allocations

const allocator = arena.allocator();

// Use freely - no individual frees needed
const user = try allocator.create(User);
const name = try allocator.dupe(u8, "Alice");
const scores = try allocator.alloc(i32, 100);
```

**Example - Request Handler:**
```zig
const std = @import("std");

fn handleRequest(base_allocator: std.mem.Allocator, request: []const u8) ![]u8 {
    // Create arena for this request
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit(); // Cleanup all temporary allocations

    const allocator = arena.allocator();

    // Parse request (many temporary allocations)
    const parsed = try parseRequest(allocator, request);
    const result = try processData(allocator, parsed);
    const response = try formatResponse(allocator, result);

    // Return response (caller must dupe if needed)
    return response;
}
```

**When to use:**
- Request/response patterns (HTTP handlers, CLI commands)
- Parsing and temporary data structures
- Many small allocations with the same lifetime
- Situations where tracking individual frees is tedious

**When NOT to use:**
- Long-running processes without clear "phases"
- When memory usage must be bounded tightly
- When individual items need different lifetimes

------

### FixedBufferAllocator

Stack-allocated fixed-size buffer allocator. Fast and predictable, but limited in size.

**Type:** `std.heap.FixedBufferAllocator`

**Key Features:**
- **Stack-based**: No heap allocations
- **Deterministic**: Fixed size known at compile time
- **Fast**: No system calls
- **Bounded**: Cannot exceed buffer size

**Example:**
```zig
const std = @import("std");

pub fn processSmallData() !void {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const data = try allocator.alloc(u8, 100);
    // Use data...

    // Can reset and reuse
    fba.reset();
    const more_data = try allocator.alloc(u8, 200);
}
```

**Methods:**
- `init(buffer: []u8)` - Initialize with buffer
- `reset()` - Reset allocator to reuse buffer
- `end_index` - Current allocation position

**When to use:**
- Small, bounded allocations
- Performance-critical paths
- Embedded systems or no-std environments
- When heap allocation is unacceptable

**When NOT to use:**
- Unknown or large allocation sizes
- Dynamic or long-lived data
- When OOM should be handled gracefully (FBA panics when full)

------

### page_allocator

Direct OS page allocator. Makes syscalls for every allocation. Simple but can be slow for small allocations.

**Type:** `std.mem.Allocator` (global constant)

**Key Features:**
- **Direct syscalls**: mmap/VirtualAlloc per allocation
- **Page-aligned**: All allocations are page-aligned
- **No metadata overhead**: Minimal bookkeeping
- **Thread-safe**: OS-level synchronization

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Efficient for large allocations
    const large_buffer = try allocator.alloc(u8, 1024 * 1024); // 1 MB
    defer allocator.free(large_buffer);

    std.debug.print("Allocated 1 MB at {*}\n", .{large_buffer.ptr});
}
```

**Page Size Constants:**
- `std.heap.page_size_min` - Minimum page size (comptime)
- `std.heap.page_size_max` - Maximum page size (comptime)
- `std.heap.pageSize()` - Runtime page size query

**When to use:**
- Large allocations (> 4 KB)
- Backing allocator for ArenaAllocator or GeneralPurposeAllocator
- Simple programs where allocation frequency is low
- Memory-mapped file-like patterns

**When NOT to use:**
- Many small allocations (syscall overhead)
- Tight loops with allocations
- When you need better than page granularity

------

### c_allocator

Wrapper around C's malloc/free. Use when interfacing with C libraries or when you need malloc compatibility.

**Type:** `std.mem.Allocator` (global constant)

**Key Features:**
- **C compatibility**: Uses malloc/realloc/free
- **Standard C semantics**: Familiar to C programmers
- **Library interop**: Works with C libraries expecting malloc'd memory
- **Arbitrary alignment**: Supports aligned allocations via posix_memalign

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // Can be passed to C functions expecting malloc'd memory
    const buffer = try allocator.alloc(u8, 256);
    defer allocator.free(buffer);

    // Works with Zig data structures too
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    try list.append(42);
}
```

**When to use:**
- C library interoperability
- Linking against libc anyway
- Familiar malloc/free semantics desired
- Production builds (mature, well-tested)

**When NOT to use:**
- When avoiding libc dependency
- When you need leak detection (use GeneralPurposeAllocator instead)
- When maximum performance is critical (syscalls may be faster)

------

## Specialized Allocators

### ThreadSafeAllocator

Wraps any allocator to make it thread-safe with a mutex.

**Type:** `std.heap.ThreadSafeAllocator`

**Example:**
```zig
const std = @import("std");

var backing_allocator = std.heap.FixedBufferAllocator.init(&buffer);
var tsa = std.heap.ThreadSafeAllocator{ .backing_allocator = backing_allocator.allocator() };
const allocator = tsa.allocator();
// Safe to use from multiple threads
```

------

### StackFallbackAllocator

Tries to allocate from a fixed stack buffer first, falls back to another allocator if that fails.

**Type:** `std.heap.StackFallbackAllocator(size)`

**Constructor:** `std.heap.stackFallback(comptime size: usize, fallback_allocator: Allocator)`

**Example:**
```zig
const std = @import("std");

pub fn optimizedAlloc() !void {
    var fallback = std.heap.stackFallback(4096, std.heap.page_allocator);
    const allocator = fallback.get();

    // Small allocations use stack (fast)
    const small = try allocator.alloc(u8, 100);
    defer allocator.free(small);

    // Large allocations fall back to page_allocator
    const large = try allocator.alloc(u8, 10000);
    defer allocator.free(large);
}
```

**When to use:**
- Optimize for the common case (small allocations)
- Want stack speed with heap fallback safety
- Performance-critical code with mostly small allocations

------

### MemoryPool

Object pool for fixed-size allocations. Very fast allocation and deallocation of same-sized objects.

**Type:** `std.heap.MemoryPool(T)` or `std.heap.MemoryPoolAligned(T, alignment)`

**Example:**
```zig
const std = @import("std");

const Node = struct {
    value: i32,
    next: ?*Node,
};

pub fn main() !void {
    var pool = std.heap.MemoryPool(Node).init(std.heap.page_allocator);
    defer pool.deinit();

    // Fast allocation from pool
    const node1 = try pool.create();
    node1.* = .{ .value = 1, .next = null };

    const node2 = try pool.create();
    node2.* = .{ .value = 2, .next = node1 };

    // Fast deallocation back to pool
    pool.destroy(node2);
    pool.destroy(node1);
}
```

**When to use:**
- Allocating many same-sized objects (linked list nodes, tree nodes)
- Frequent allocation/deallocation cycles
- Object pooling pattern
- Performance-critical data structure implementations

------

### DebugAllocator

Wrapper that adds debug logging and validation around another allocator.

**Type:** `std.heap.DebugAllocator`

**Example:**
```zig
var debug_alloc = std.heap.DebugAllocator(.{ .safety = true }){
    .backing_allocator = std.heap.page_allocator,
};
const allocator = debug_alloc.allocator();
// Logs all allocations and checks for errors
```

------

### SmpAllocator

Symmetric multiprocessing allocator for multi-threaded workloads.

**Type:** `std.heap.SmpAllocator`
**Global:** `std.heap.smp_allocator`

**When to use:** Multi-threaded applications with heavy allocation patterns.

------

### WasmAllocator / wasm_allocator

WebAssembly-specific allocator optimized for WASM environments.

**Type:** `std.heap.WasmAllocator`
**Global:** `std.heap.wasm_allocator`

**When to use:** WebAssembly targets, especially in ReleaseSmall mode.

------

## Usage Patterns

### Pattern 1: Standard Application Setup

```zig
const std = @import("std");

pub fn main() !void {
    // Use GPA for development
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
  const deinit_status = gpa.deinit();
  if (deinit_status == .leak) @panic("LEAK");
    }
    const allocator = gpa.allocator();

    // Pass allocator to your application
    try runApp(allocator);
}

fn runApp(allocator: std.mem.Allocator) !void {
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    try list.append("Hello");
    try list.append("World");
}
```

### Pattern 2: Request Handler with Arena

```zig
const std = @import("std");

fn handleHttpRequest(
    base_allocator: std.mem.Allocator,
    request: []const u8,
) ![]u8 {
    // Arena for request-scoped allocations
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse, process, format - all cleaned up automatically
    const parsed = try parseRequest(allocator, request);
    const response = try buildResponse(allocator, parsed);

    // Duplicate for caller (lives beyond arena)
    return base_allocator.dupe(u8, response);
}
```

### Pattern 3: Bounded Stack-First Allocation

```zig
const std = @import("std");

fn parseCommand(input: []const u8) ![]const u8 {
    // Try stack first, fall back to heap if needed
    var fallback = std.heap.stackFallback(1024, std.heap.page_allocator);
    const allocator = fallback.get();

    const trimmed = std.mem.trim(u8, input, " \t\n");
    return allocator.dupe(u8, trimmed);
}
```

### Pattern 4: Object Pool for Performance

```zig
const std = @import("std");

const Message = struct {
    id: u64,
    payload: [256]u8,
};

var message_pool: std.heap.MemoryPool(Message) = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    message_pool = std.heap.MemoryPool(Message).init(allocator);
}

pub fn deinit() void {
    message_pool.deinit();
}

fn createMessage(id: u64) !*Message {
    const msg = try message_pool.create();
    msg.* = .{ .id = id, .payload = undefined };
    return msg;
}

fn destroyMessage(msg: *Message) void {
    message_pool.destroy(msg);
}
```

### Pattern 5: Allocator Testing

```zig
const std = @import("std");

test "allocator basic usage" {
    // Use testing.allocator for tests - checks for leaks
    const allocator = std.testing.allocator;

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    // If you forget to free, test will fail!
    try std.testing.expect(bytes.len == 100);
}
```

------

## Allocator Interface

All allocators implement the `std.mem.Allocator` interface:

### Core Methods

**`alloc(comptime T: type, n: usize) ![]T`**
- Allocates slice of `n` items of type `T`
- Returns `error.OutOfMemory` if allocation fails

**`free(slice: anytype) void`**
- Frees previously allocated slice
- Must pass the exact same slice returned by alloc

**`create(comptime T: type) !*T`**
- Allocates single item of type `T`
- Returns pointer to uninitialized memory

**`destroy(ptr: anytype) void`**
- Frees single item previously allocated with create

**`realloc(slice: anytype, new_n: usize) ![]T`**
- Resizes allocation to `new_n` items
- May move memory, returns new slice

**`dupe(comptime T: type, m: []const T) ![]T`**
- Allocates and copies slice
- Returns owned duplicate

**`dupeZ(comptime T: type, m: []const T) ![:0]T`**
- Like dupe but adds sentinel (null terminator)
- Useful for C string interop

------

## Error Sets

### OutOfMemory
`error.OutOfMemory` - Allocation failed, no memory available

------

## Debug Checklist

✅ **Always free what you allocate** - Every `alloc`, `create`, or `dupe` needs a corresponding `free`, `destroy`, or arena `deinit`

✅ **Use defer immediately** - Place `defer` right after allocation to prevent leaks:
```zig
const data = try allocator.alloc(u8, 100);
defer allocator.free(data); // ✅ Immediately after
```

✅ **Check GeneralPurposeAllocator.deinit() return** - Always check for leaks:
```zig
const deinit_status = gpa.deinit();
if (deinit_status == .leak) @panic("LEAK!");
```

✅ **Don't free arena allocations individually** - ArenaAllocator frees everything at once, individual frees will crash

✅ **Match allocator on free** - Must free with the same allocator used to allocate

✅ **Use std.testing.allocator in tests** - Automatically detects leaks in tests

✅ **Don't store slices across realloc** - After realloc, old slice is invalid

✅ **FixedBufferAllocator panics when full** - Not suitable when graceful OOM handling is needed

✅ **Check capacity before FixedBufferAllocator use** - Or use StackFallbackAllocator for safety

✅ **ArenaAllocator needs backing allocator** - Don't forget to deinit the backing allocator too

------

## Performance Tips

1. **Choose the right allocator for the job:**
   - **Hot loops**: FixedBufferAllocator or MemoryPool
   - **Request/response**: ArenaAllocator
   - **Large allocations**: page_allocator
   - **Development**: GeneralPurposeAllocator

2. **Use ArenaAllocator for temporary allocations:**
   ```zig
   var arena = std.heap.ArenaAllocator.init(base);
   defer arena.deinit();
   // Much faster than tracking individual frees
   ```

3. **Pre-allocate when size is known:**
   ```zig
   var list = std.ArrayList(T).init(allocator);
   try list.ensureTotalCapacity(expected_size); // One allocation
   ```

4. **Batch allocations with ArenaAllocator** - Reduces allocator overhead

5. **Use MemoryPool for same-sized objects** - Eliminates fragmentation, very fast

6. **StackFallbackAllocator for common cases** - Zero-cost for small allocations:
   ```zig
   var fallback = std.heap.stackFallback(4096, heap_allocator);
   // Fast path for <= 4KB, fallback for larger
   ```

7. **Avoid page_allocator for tiny allocations** - Syscall overhead dominates

8. **Profile before optimizing** - GeneralPurposeAllocator is often fast enough

9. **Use GeneralPurposeAllocator in development** - Catch bugs early even if slightly slower

10. **Consider alignment requirements** - Over-aligned allocations may waste memory

------

## See Also

- **std.mem** - Memory utilities (copy, compare, set, searching)
- **std.ArrayList** - Dynamic array using allocators
- **std.HashMap** - Hash map using allocators
- **std.fmt.allocPrint** - Formatted string allocation
- **std.testing.allocator** - Special allocator for tests with leak detection
