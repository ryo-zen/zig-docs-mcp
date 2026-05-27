# std.BitStack

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code demonstrating all BitStack operations: `test_bitstack_basic.zig`, `test_bitstack_capacity.zig`, `test_bitstack_standalone.zig`

## Quick Start

**Basic Stack Operations**
```zig
const std = @import("std");
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();

var stack = std.BitStack.init(da.allocator());
defer stack.deinit();

try stack.push(1);
try stack.push(0);
try stack.push(1);

const top = stack.peek(); // Returns 1 without removing
const bit = stack.pop();  // Returns 1 and removes it
```

**Pre-allocated for Known Size**
```zig
var stack = std.BitStack.init(da.allocator());
defer stack.deinit();

// Pre-allocate for 1000 bits to avoid repeated allocations
try stack.ensureTotalCapacity(1000);

var i: usize = 0;
while (i < 1000) : (i += 1) {
    try stack.push(@intCast(i % 2));
}
```

**Stack-Allocated (No Heap)**
```zig
// Use WithState functions for fixed-size buffers
var buffer: [128]u8 = undefined; // Can hold 1024 bits
var bit_len: usize = 0;

std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 0);

const top = std.BitStack.peekWithState(&buffer, bit_len);
const bit = std.BitStack.popWithState(&buffer, &bit_len);
```

---

## Overview

`std.BitStack` is a memory-efficient stack data structure for storing sequences of single-bit (`u1`) values. It packs 8 bits into each byte of storage using an underlying `ArrayList(u8)`, making it 8× more memory-efficient than storing bits as individual bytes or integers.

The stack follows Last-In-First-Out (LIFO) semantics: the most recently pushed bit is the first one popped. BitStack is particularly useful for algorithms that need to track binary state efficiently, such as tree traversals, bit-level parsing, or compression algorithms.

**Key Characteristics:**
- **Memory efficient** - 8 bits packed per byte of storage
- **Dynamic growth** - Automatically resizes as needed (with allocator)
- **LIFO semantics** - Standard stack push/pop/peek operations
- **Flexible allocation** - Works with heap (init) or stack (WithState functions)
- **Bit-level indexing** - Tracks bit count separately from byte storage

**When to use:**
- Tracking binary state in algorithms (visited flags, decision trees)
- Bit-level parsing or serialization
- Compression or encoding algorithms
- When you need a stack but memory efficiency is critical
- Situations where `ArrayList(bool)` would waste 7 bits per element

---

## Fields

`bytes: std.array_list.Managed(u8)`

The underlying byte storage that holds the packed bits. Each byte stores 8 bits, filled from least significant bit (LSB) to most significant bit (MSB). This field is managed by the BitStack and should not be modified directly.

------

`bit_len: usize = 0`

The total number of bits currently stored in the stack. This count is independent of the byte array length - for example, `bit_len` of 13 would require 2 bytes of storage (`bytes.items.len == 2`), with 5 bits unused in the second byte.

---

## Core Functions

### `pub fn init(allocator: Allocator) @This()`

Creates a new empty BitStack backed by the given allocator. The stack starts with zero capacity and will grow dynamically as bits are pushed.

**Example:**
```zig
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();

var stack = std.BitStack.init(da.allocator());
defer stack.deinit();

// Stack is ready to use
```

------

### `pub fn deinit(self: *@This()) void`

Frees all memory allocated by the BitStack. After calling `deinit()`, the stack is in an undefined state and must not be used.

**Example:**
```zig
var stack = std.BitStack.init(allocator);
defer stack.deinit(); // Cleans up automatically

try stack.push(1);
// ... use the stack ...
// deinit called automatically on scope exit
```

------

### `pub fn push(self: *@This(), b: u1) Allocator.Error!void`

Pushes a single bit onto the top of the stack. If the underlying storage is full, it will automatically allocate more space. This operation may fail with `Allocator.Error` if memory allocation fails.

**Parameters:**
- `b: u1` - The bit value to push (0 or 1)

**Example:**
```zig
var stack = std.BitStack.init(allocator);
defer stack.deinit();

try stack.push(1);
try stack.push(0);
try stack.push(1);
// Stack now contains [1, 0, 1] with 1 at the top
```

------

### `pub fn pop(self: *@This()) u1`

Removes and returns the bit at the top of the stack. The caller is responsible for ensuring the stack is not empty - popping from an empty stack has undefined behavior.

**Returns:** The bit value (0 or 1) that was at the top of the stack.

**Example:**
```zig
try stack.push(1);
try stack.push(0);

const bit = stack.pop(); // Returns 0
const next = stack.pop(); // Returns 1
// Stack is now empty
```

------

### `pub fn peek(self: *const @This()) u1`

Returns the bit at the top of the stack without removing it. The stack length remains unchanged. Peeking at an empty stack has undefined behavior.

**Returns:** The bit value (0 or 1) at the top of the stack.

**Example:**
```zig
try stack.push(1);

const bit = stack.peek(); // Returns 1
// Stack still contains 1
const same = stack.peek(); // Still returns 1
```

---

## Capacity Management Functions

### `pub fn ensureTotalCapacity(self: *@This(), bit_capacity: usize) Allocator.Error!void`

Pre-allocates storage to hold at least `bit_capacity` bits without requiring additional allocations. This is useful when you know the maximum size in advance and want to avoid repeated allocations during push operations.

**Parameters:**
- `bit_capacity: usize` - The minimum number of bits the stack should be able to hold

**Example:**
```zig
var stack = std.BitStack.init(allocator);
defer stack.deinit();

// Pre-allocate for 10,000 bits
try stack.ensureTotalCapacity(10000);

// Now push 10,000 bits without additional allocations
var i: usize = 0;
while (i < 10000) : (i += 1) {
    try stack.push(1);
}
```

---

## Standalone Functions (Stack-Allocated Pattern)

These functions operate on raw byte buffers without requiring a BitStack instance or heap allocation. They're useful when you know the maximum size at compile time and want to avoid dynamic allocation entirely.

### `pub fn peekWithState(buf: []const u8, bit_len: usize) u1`

Peeks at the top bit in a manually-managed buffer. The buffer and bit length represent the stack state.

**Parameters:**
- `buf: []const u8` - The byte buffer containing packed bits
- `bit_len: usize` - The current number of bits in the stack

**Returns:** The bit value (0 or 1) at the top of the stack.

**Example:**
```zig
var buffer: [10]u8 = undefined;
var bit_len: usize = 0;

std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
const top = std.BitStack.peekWithState(&buffer, bit_len); // Returns 1
```

------

### `pub fn popWithState(buf: []const u8, bit_len: *usize) u1`

Pops the top bit from a manually-managed buffer, decrementing the bit length.

**Parameters:**
- `buf: []const u8` - The byte buffer containing packed bits
- `bit_len: *usize` - Pointer to the current bit count (will be decremented)

**Returns:** The bit value (0 or 1) that was at the top of the stack.

**Example:**
```zig
var buffer: [10]u8 = undefined;
var bit_len: usize = 3; // Assume 3 bits already in buffer

const bit = std.BitStack.popWithState(&buffer, &bit_len);
// bit_len is now 2
```

------

### `pub fn pushWithStateAssumeCapacity(buf: []u8, bit_len: *usize, b: u1) void`

Pushes a bit onto a manually-managed buffer, incrementing the bit length. The caller must ensure the buffer has sufficient capacity - this function will not check and may write out of bounds if the buffer is full.

**Parameters:**
- `buf: []u8` - The byte buffer for packed bits
- `bit_len: *usize` - Pointer to the current bit count (will be incremented)
- `b: u1` - The bit value to push (0 or 1)

**Example:**
```zig
var buffer: [128]u8 = undefined; // 1024 bits capacity
var bit_len: usize = 0;

// Safe because we know buffer can hold 1024 bits
var i: usize = 0;
while (i < 1000) : (i += 1) {
    std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
}
```

---

## Usage Patterns

### Pattern 1: Algorithm State Tracking

```zig
// Track visited nodes in tree traversal
var visited = std.BitStack.init(allocator);
defer visited.deinit();

try visited.ensureTotalCapacity(node_count);

fn dfs(node: *Node, visited: *BitStack) !void {
    try visited.push(1); // Mark as visiting
    defer _ = visited.pop(); // Unmark on return

    for (node.children) |child| {
  if (!child.visited) {
      try dfs(child, visited);
  }
    }
}
```

### Pattern 2: Bit-Level Parsing

```zig
// Parse bits from a stream
var bit_buffer = std.BitStack.init(allocator);
defer bit_buffer.deinit();

while (try readByte(stream)) |byte| {
    var i: u3 = 0;
    while (i < 8) : (i += 1) {
  const bit: u1 = @intCast((byte >> i) & 1);
  try bit_buffer.push(bit);
    }
}

// Process bits in LIFO order
while (bit_buffer.bit_len > 0) {
    const bit = bit_buffer.pop();
    // ... process bit ...
}
```

### Pattern 3: Stack-Allocated for Known Size

```zig
// No heap allocation needed
fn processBitSequence(bits: []const u1) !void {
    var buffer: [64]u8 = undefined; // 512 bits max
    var bit_len: usize = 0;

    for (bits) |bit| {
  if (bit_len >= 512) return error.TooManyBits;
  std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, bit);
    }

    // Process in reverse
    while (bit_len > 0) {
  const bit = std.BitStack.popWithState(&buffer, &bit_len);
  // ... process bit ...
    }
}
```

---

## Error Sets

`Allocator.Error`

Returned by `push()` and `ensureTotalCapacity()` when memory allocation fails. Common errors include:
- `OutOfMemory` - The allocator cannot provide more memory

---

## Debug Checklist

✅ **Check stack is not empty before pop/peek** - These functions don't check for underflow; popping from an empty stack is undefined behavior.

✅ **Remember to call deinit()** - BitStack allocates memory that must be freed. Use `defer stack.deinit();` immediately after init.

✅ **WithState functions don't check capacity** - `pushWithStateAssumeCapacity` will write out of bounds if the buffer is full. Calculate capacity as `buffer.len * 8` bits.

✅ **Bit length is separate from byte length** - `bit_len` tracks individual bits, while `bytes.items.len` tracks bytes. A bit_len of 9 requires 2 bytes.

✅ **Don't modify fields directly** - The `bytes` and `bit_len` fields are managed together. Modifying one without the other breaks invariants.

✅ **Pre-allocate for large sequences** - Use `ensureTotalCapacity()` when you know the size to avoid O(n) allocations during push.

---

## Performance Tips

1. **Pre-allocate when size is known** - Call `ensureTotalCapacity(n)` before pushing n bits to avoid repeated allocations and copies.

2. **Use WithState for small, known sizes** - Stack-allocated buffers avoid heap allocation overhead entirely. Each byte holds 8 bits, so a `[128]u8` buffer can hold 1024 bits.

3. **Batch operations** - If pushing many bits from a byte source, consider processing full bytes at a time rather than individual bits.

4. **Memory efficiency** - BitStack uses 1 byte per 8 bits, plus ArrayList overhead. For fewer than 64 bits, a single `u64` might be more efficient.

5. **Avoid pop/push cycles** - If you need to examine and replace the top bit, use `peek()` to check without removing, then only pop if needed.

---

## See Also

- **`std.ArrayList`** - The underlying storage mechanism for the byte array
- **`std.DynamicBitSet`** - For bit sets with random access (not just stack operations)
- **`std.StaticBitSet`** - Compile-time sized bit set for fixed-size collections
- Packed integer arrays - For arrays of integers with non-byte sizes
