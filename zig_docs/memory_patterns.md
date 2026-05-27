# Memory Management Patterns

Practical patterns for memory allocation and cleanup in Zig.

## Table of Contents
- [Basic Allocation](#basic-allocation)
- [Zig 0.16 Allocator Patterns](#zig-016-allocator-patterns)
- [Multi-Step Allocation](#multi-step-allocation)
- [Arena Allocator Pattern](#arena-allocator-pattern)
- [Fixed Buffer Allocator](#fixed-buffer-allocator)
- [Memory Pool Pattern](#memory-pool-pattern)
- [Common Mistakes](#common-mistakes)

---

## Basic Allocation

### Single Buffer Allocation

```zig
fn processData(allocator: std.mem.Allocator) !void {
    // Allocate
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);  // ✅ Guaranteed cleanup

    // Use buffer...
}
```

**Key points:**
- `defer` immediately after allocation
- Runs even if error occurs later
- No need to track success/failure

---

### Create/Destroy Pattern

For single-item allocation:

```zig
fn example(allocator: std.mem.Allocator) !void {
    // Create single item
    const ptr = try allocator.create(MyStruct);
    defer allocator.destroy(ptr);  // ✅ Cleanup

    // Initialize
    ptr.* = MyStruct{
  .field1 = 42,
  .field2 = "hello",
    };

    // Use ptr...
}
```

**`create` vs `alloc`:**
- `create(T)` - Allocate space for **one** T, returns `*T`
- `alloc(T, n)` - Allocate space for **n** T's, returns `[]T`

---

### Resize Pattern

For dynamic growth:

```zig
var buffer = try allocator.alloc(u8, 100);
defer allocator.free(buffer);

// Need more space?
buffer = try allocator.realloc(buffer, 200);  // Resizes, may move
// defer still works - it references the same variable
```

---

## Zig 0.16 Allocator Patterns

In Zig 0.16, many standard library types changed to "unmanaged" - they don't store the allocator.

### ArrayList - Always Pass Allocator

```zig
var list = std.ArrayList(u8).empty;  // ✅ Use .empty constant (0.16)
defer list.deinit(allocator);        // ✅ Pass allocator to deinit

try list.append(allocator, 'x');     // ✅ Pass allocator to all operations
try list.appendSlice(allocator, "hello");
try list.ensureTotalCapacity(allocator, 100);
```

**Old API (pre-0.16):**
```zig
var list = std.ArrayList(u8).init(allocator);  // ❌ No longer works
try list.append('x');                          // ❌ Missing allocator
list.deinit();                                 // ❌ Missing allocator
```

---

### HashMap - Always Pass Allocator

```zig
var map = std.AutoHashMap([]const u8, i32).empty;  // ✅ 0.16 style
defer map.deinit(allocator);

try map.put(allocator, "key", 42);  // ✅ Pass allocator
```

---

### MemoryPool - Always Pass Allocator

```zig
var pool = std.heap.MemoryPool(Thing).empty;  // ✅ Use .empty
defer pool.deinit(allocator);                 // ✅ Pass allocator to deinit

const item = try pool.create(allocator);      // ✅ Pass allocator to create
pool.destroy(item);                           // ✅ destroy doesn't need allocator
```

**Why destroy doesn't need allocator:**
- `destroy` just returns memory to the pool
- `deinit` (which needs allocator) actually frees the pool

---

## Multi-Step Allocation

### Pattern: Progressive errdefer

Each allocation adds its own cleanup:

```zig
fn setupResources(allocator: std.mem.Allocator) !Resources {
    // Step 1
    const buf1 = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buf1);  // ✅ Only if subsequent error

    // Step 2
    const buf2 = try allocator.alloc(u8, 2048);
    errdefer allocator.free(buf2);  // ✅ Only if subsequent error

    // Step 3
    const buf3 = try allocator.alloc(u8, 4096);
    errdefer allocator.free(buf3);

    // Success: caller owns all three buffers
    return Resources{ .a = buf1, .b = buf2, .c = buf3 };
}
```

**How it works:**
- Each `errdefer` only runs if an error occurs **after** that point
- If all allocations succeed, no errdefers run
- Caller receives all resources and must clean them up

---

### Pattern: Struct with Cleanup

Standard pattern for types that manage memory:

```zig
const Database = struct {
    connection_pool: []Connection,
    cache: []CacheEntry,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, pool_size: usize) !Database {
  // Allocate connection pool
  const pool = try allocator.alloc(Connection, pool_size);
  errdefer allocator.free(pool);  // Cleanup if cache alloc fails

  // Allocate cache
  const cache = try allocator.alloc(CacheEntry, 1000);
  errdefer allocator.free(cache);  // Cleanup if init fails

  // Initialize connections
  for (pool) |*conn| {
      conn.* = try Connection.init(allocator);
  }
  // Note: If this fails, errdefer above frees pool memory
  // but doesn't deinit the successfully initialized connections
  // For production code, you'd need more sophisticated cleanup

  return Database{
      .connection_pool = pool,
      .cache = cache,
      .allocator = allocator,
  };
    }

    fn deinit(self: *Database) void {
  // Clean up in reverse order
  for (self.connection_pool) |*conn| {
      conn.deinit();
  }
  self.allocator.free(self.cache);
  self.allocator.free(self.connection_pool);
    }
};

// Usage
var db = try Database.init(allocator, 10);
defer db.deinit();
```

---

### Pattern: Robust Multi-Step Init

For production code with proper cleanup at each step:

```zig
fn init(allocator: std.mem.Allocator) !Database {
    var pool: []Connection = &[_]Connection{};
    errdefer allocator.free(pool);

    var initialized: usize = 0;
    errdefer {
  // Deinit all successfully initialized connections
  for (pool[0..initialized]) |*conn| {
      conn.deinit();
  }
    }

    // Allocate
    pool = try allocator.alloc(Connection, 10);

    // Initialize one by one
    for (pool) |*conn| {
  conn.* = try Connection.init(allocator);
  initialized += 1;  // Track successful inits
    }

    return Database{ .connection_pool = pool, .allocator = allocator };
}
```

---

## Arena Allocator Pattern

Arena allocator is great for **temporary allocations** that all die together:

### Pattern: Scoped Arena

```zig
fn processRequest(parent_allocator: std.mem.Allocator) !Response {
    // Create arena for request-scoped allocations
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();  // ✅ Frees ALL arena allocations at once

    const allocator = arena.allocator();

    // Allocate freely - all cleaned up together
    const temp1 = try allocator.alloc(u8, 100);
    const temp2 = try allocator.alloc(u8, 200);
    const temp3 = try parseData(allocator);  // May do many allocations

    // No need to free individual allocations
    // arena.deinit() cleans up everything

    return buildResponse(temp1, temp2, temp3);
}
```

**When to use arena:**
- Request/response handling
- Parsing temporary data
- Building temporary structures
- Any scenario where all allocations die together

**When NOT to use arena:**
- Long-lived allocations
- When individual items need different lifetimes
- When you need to free individual items

---

### Pattern: Arena with Parent Allocator

```zig
const Server = struct {
    da: std.heap.DebugAllocator(.{}),

    fn handleRequest(self: *Server, request: Request) !Response {
  // Arena for this request only
  var arena = std.heap.ArenaAllocator.init(self.da.allocator());
  defer arena.deinit();

  return try processRequest(arena.allocator(), request);
    }
};
```

---

## Fixed Buffer Allocator

For stack-allocated, bounded memory:

### Pattern: Stack Buffer

```zig
fn example() !void {
    // Allocate buffer on stack
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Use like normal allocator, but limited to buffer size
    const data = try allocator.alloc(u8, 100);  // OK
    const more = try allocator.alloc(u8, 5000); // ERROR: OutOfMemory

    // No deinit needed - buffer is on stack
}
```

**When to use:**
- Stack-only allocation
- Embedded systems
- When maximum memory usage is known
- Testing (controlled memory environment)

---

### Pattern: Fixed Buffer Arena

Combine with arena for no-free semantics:

```zig
fn example() !void {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    var arena = std.heap.ArenaAllocator.init(fba.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    // Allocate without worrying about freeing
    const a = try allocator.alloc(u8, 100);
    const b = try allocator.alloc(u8, 200);
    // ...
}
```

---

## Memory Pool Pattern

For frequent allocation/deallocation of same-sized objects:

### Pattern: Object Pool

```zig
const Server = struct {
    connection_pool: std.heap.MemoryPool(Connection),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) Server {
  return Server{
      .connection_pool = std.heap.MemoryPool(Connection).empty,  // ✅ 0.16
      .allocator = allocator,
  };
    }

    fn deinit(self: *Server) void {
  self.connection_pool.deinit(self.allocator);  // ✅ Pass allocator (0.16)
    }

    fn getConnection(self: *Server) !*Connection {
  // Get from pool (or allocate new)
  const conn = try self.connection_pool.create(self.allocator);  // ✅ 0.16
  errdefer self.connection_pool.destroy(conn);

  try conn.init();
  return conn;
    }

    fn releaseConnection(self: *Server, conn: *Connection) void {
  conn.deinit();
  self.connection_pool.destroy(conn);  // Returns to pool
    }
};
```

**When to use:**
- Frequent create/destroy of same-size objects
- Connection pools
- Particle systems
- Object recycling

---

## Common Mistakes

### Mistake 1: Missing defer

```zig
// ❌ BAD: No cleanup
const buffer = try allocator.alloc(u8, 1024);
// ... use buffer ...
// If error happens, memory leaks!

// ✅ GOOD: Immediate defer
const buffer = try allocator.alloc(u8, 1024);
defer allocator.free(buffer);
```

---

### Mistake 2: defer in wrong scope

```zig
// ❌ BAD: defer outside loop
for (items) |item| {
    const data = try allocator.alloc(u8, 1024);
    // ... process ...
}
defer allocator.free(data);  // ERROR: data not in scope

// ✅ GOOD: defer inside loop
for (items) |item| {
    const data = try allocator.alloc(u8, 1024);
    defer allocator.free(data);  // Freed each iteration
    // ... process ...
}
```

---

### Mistake 3: Using defer instead of errdefer

```zig
// ❌ BAD: Always frees, even on success
fn example() ![]u8 {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);  // BUG: Frees before returning!
    return buffer;  // Returns freed memory
}

// ✅ GOOD: Only free on error
fn example() ![]u8 {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);  // Only if error
    return buffer;  // Caller owns buffer
}
```

---

### Mistake 4: Forgetting allocator parameter (Zig 0.16)

```zig
// ❌ BAD: Old API
var list = std.ArrayList(u8).init(allocator);
try list.append('x');

// ✅ GOOD: New API (0.16)
var list = std.ArrayList(u8).empty;
try list.append(allocator, 'x');
list.deinit(allocator);
```

---

### Mistake 5: Double Free

```zig
// ❌ BAD: Freeing twice
const buffer = try allocator.alloc(u8, 1024);
allocator.free(buffer);
allocator.free(buffer);  // BUG: Double free

// ✅ GOOD: Set to undefined or use flag
const buffer = try allocator.alloc(u8, 1024);
allocator.free(buffer);
// buffer = undefined;  // Can't accidentally use
```

---

### Mistake 6: Not using errdefer for partial cleanup

```zig
// ❌ BAD: Leaks buf1 if buf2 allocation fails
fn example() !Resources {
    const buf1 = try allocator.alloc(u8, 1024);
    const buf2 = try allocator.alloc(u8, 2048);  // If this fails, buf1 leaks
    return Resources{ .a = buf1, .b = buf2 };
}

// ✅ GOOD: errdefer cleans up on error
fn example() !Resources {
    const buf1 = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buf1);  // Cleanup if buf2 fails

    const buf2 = try allocator.alloc(u8, 2048);
    errdefer allocator.free(buf2);

    return Resources{ .a = buf1, .b = buf2 };
}
```

---

## See Also

- [error_patterns.md](error_patterns.md) - Error handling with memory cleanup
- [common_errors.md](common_errors.md) - Common memory-related errors
- [migration_016.md](migration_016.md) - Zig 0.16 allocator changes
