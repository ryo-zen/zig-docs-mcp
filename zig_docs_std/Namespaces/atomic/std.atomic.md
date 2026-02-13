# std.atomic

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all atomic features

## Quick Start

### Most Common Patterns

**Atomic Counter**
```zig
const std = @import("std");
var counter = std.atomic.Value(usize).init(0);

// Increment atomically
_ = counter.fetchAdd(1, .monotonic);

// Read current value
const value = counter.load(.monotonic);
```

**Atomic Flag / Lock**
```zig
var flag = std.atomic.Value(bool).init(false);

// Try to acquire
const was_set = flag.swap(true, .acquire);
if (!was_set) {
    // Successfully acquired the flag
    defer flag.store(false, .release);
    // ... critical section ...
}
```

**Compare-And-Swap (CAS)**
```zig
var value = std.atomic.Value(i32).init(10);

// Try to change 10 to 20
const old = value.cmpxchgStrong(10, 20, .seq_cst, .seq_cst);
if (old == null) {
    // Successfully changed from 10 to 20
} else {
    // Value was not 10, got `old.?` instead
}
```

**Spin Loop Hint**
```zig
while (flag.load(.acquire)) {
    std.atomic.spinLoopHint(); // Yield CPU resources
}
```

**Cache-Line Aligned Atomics (Prevent False Sharing)**
```zig
const AtomicCounter = struct {
    count: std.atomic.Value(usize),
    padding: [std.atomic.cache_line - @sizeOf(std.atomic.Value(usize))]u8 = undefined,
};
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Read value | `load()` | `value.load(.monotonic)` |
| Write value | `store()` | `value.store(42, .release)` |
| Swap value | `swap()` | `old = value.swap(new, .seq_cst)` |
| Add to value | `fetchAdd()` | `old = value.fetchAdd(5, .monotonic)` |
| Subtract from value | `fetchSub()` | `old = value.fetchSub(3, .monotonic)` |
| Compare-and-swap | `cmpxchgStrong()` | `value.cmpxchgStrong(old, new, .seq_cst, .seq_cst)` |
| Bitwise OR | `fetchOr()` | `old = value.fetchOr(mask, .seq_cst)` |
| Set bit | `bitSet()` | `was = value.bitSet(5, .seq_cst)` |

### ⚠️ Critical: Memory Ordering

```zig
// WRONG - Using .monotonic for synchronization (data race!)
shared_data = compute_result();
flag.store(true, .monotonic);  // ❌ Other threads may not see shared_data!

// CORRECT - Use .release to publish data
shared_data = compute_result();
flag.store(true, .release);    // ✅ Synchronizes with acquire loads

// CORRECT - Use .acquire to read synchronized data
while (!flag.load(.acquire)) { // ✅ Sees all data written before release
    std.atomic.spinLoopHint();
}
const data = shared_data; // Safe to read
```

---

## Overview

`std.atomic` provides lock-free atomic operations for thread-safe concurrent programming. It wraps primitive values to prevent data races while enabling efficient lock-free algorithms through hardware-supported atomic instructions.

**Key Characteristics:**
- **Lock-free**: Uses CPU atomic instructions, no kernel involvement for basic operations
- **Type-safe wrapper**: `Value(T)` prevents accidental non-atomic access
- **Memory ordering control**: Explicit control over synchronization strength (`.monotonic`, `.acquire`, `.release`, `.seq_cst`)
- **Rich operation set**: Load, store, swap, compare-and-swap, arithmetic, bitwise ops
- **Cross-platform**: Works on all architectures with appropriate fallbacks
- **Zero-cost abstraction**: Compiles directly to atomic CPU instructions

**When to use std.atomic:**
- Implementing lock-free data structures (queues, stacks, counters)
- Building synchronization primitives (mutexes, semaphores, barriers)
- Managing shared state between threads without locks
- Reference counting and resource management
- Thread-safe flags and status indicators
- Performance-critical concurrent code where locks are too expensive

**When NOT to use std.atomic:**
- Simple single-threaded code (unnecessary overhead)
- When a mutex would be clearer and performance is not critical
- Complex multi-field updates (use mutexes to protect larger data structures)

---

## Core Types

### `Value(T)`

Thread-safe atomic wrapper around a primitive value. The primary type for atomic operations.

**Type Parameter:**
- `T` - Must be a primitive type suitable for atomic operations (integers, floats, bools, pointers, enums)

**Fields:**
- `raw: T` - The underlying value (⚠️ direct access risks data races - use atomic methods instead)

**Example:**
```zig
var atomic_counter = std.atomic.Value(usize).init(0);
var atomic_flag = std.atomic.Value(bool).init(false);
var atomic_ptr = std.atomic.Value(?*Node).init(null);
```

---

## Memory Ordering

Understanding memory ordering is critical for correct atomic usage. Zig uses the same memory ordering model as C11/C++11 atomics.

### `std.builtin.AtomicOrder` Enum Values

**`.unordered`** - No synchronization or ordering constraints
- Fastest, but provides no guarantees about visibility or ordering
- Use only for completely independent operations (rare)

**`.monotonic`** - Atomic operation only, no synchronization
- Guarantees the operation itself is atomic (no torn reads/writes)
- Does NOT synchronize with other threads
- Good for independent counters or statistics

**`.acquire`** - Synchronizes-with release stores
- All memory reads/writes after this load cannot be reordered before it
- Use when reading a flag/lock to access shared data

**`.release`** - Pairs with acquire loads
- All memory reads/writes before this store cannot be reordered after it
- Use when writing a flag/lock after updating shared data

**`.acq_rel`** - Acquire + Release
- Combines both acquire and release semantics
- Use for read-modify-write operations that both read and publish data

**`.seq_cst`** - Sequentially consistent (strongest guarantee)
- Total order across all seq_cst operations on all threads
- Most expensive but easiest to reason about
- Use when in doubt or when total ordering is required

### Ordering Guidelines

```zig
// Pattern: Producer-Consumer with acquire-release
// Producer:
data.value = compute();
ready_flag.store(true, .release);  // Publishes `data.value`

// Consumer:
while (!ready_flag.load(.acquire)) {  // Synchronizes with release
    std.atomic.spinLoopHint();
}
process(data.value);  // Safe - sees producer's write

// Pattern: Reference counting
fn increment(rc: *std.atomic.Value(usize)) void {
    _ = rc.fetchAdd(1, .monotonic);  // No synchronization needed
}

fn decrement(rc: *std.atomic.Value(usize)) void {
    if (rc.fetchSub(1, .release) == 1) {  // Publish all uses
  _ = rc.load(.acquire);  // Sync with other decrements
  destroyObject();
    }
}
```

---

## Read/Write Functions

### `pub fn init(value: T) Self`

Creates a new atomic value initialized to the given value.

**Parameters:**
- `value` - Initial value

**Returns:** New `Value(T)` instance

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var counter = std.atomic.Value(usize).init(42);
    var flag = std.atomic.Value(bool).init(false);
    var shared_ptr = std.atomic.Value(?*Data).init(null);

    std.debug.print("Counter: {}\n", .{counter.load(.monotonic)});
}
```

------

### `pub inline fn load(self: *const Self, comptime order: AtomicOrder) T`

Atomically reads the current value.

**Parameters:**
- `order` - Memory ordering (typically `.monotonic`, `.acquire`, or `.seq_cst`)

**Returns:** Current value

**Valid orderings:** `.unordered`, `.monotonic`, `.acquire`, `.seq_cst`
**Invalid orderings:** `.release`, `.acq_rel` (loads cannot release)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var counter = std.atomic.Value(usize).init(100);

    const value = counter.load(.monotonic);
    std.debug.print("Counter value: {}\n", .{value});

    // Use .acquire when synchronizing with releases
    const synchronized_value = counter.load(.acquire);
}
```

------

### `pub inline fn store(self: *Self, value: T, comptime order: AtomicOrder) void`

Atomically writes a new value.

**Parameters:**
- `value` - New value to store
- `order` - Memory ordering (typically `.monotonic`, `.release`, or `.seq_cst`)

**Valid orderings:** `.unordered`, `.monotonic`, `.release`, `.seq_cst`
**Invalid orderings:** `.acquire`, `.acq_rel` (stores cannot acquire)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var counter = std.atomic.Value(usize).init(0);

    counter.store(42, .monotonic);

    // Use .release when publishing data
    counter.store(99, .release);

    std.debug.print("Final value: {}\n", .{counter.load(.monotonic)});
}
```

------

### `pub inline fn swap(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically replaces the value and returns the old value.

**Parameters:**
- `operand` - New value to store
- `order` - Memory ordering (any ordering valid)

**Returns:** Previous value before the swap

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var value = std.atomic.Value(i32).init(10);

    const old = value.swap(20, .seq_cst);
    std.debug.print("Old: {}, New: {}\n", .{old, value.load(.monotonic)});
    // Output: Old: 10, New: 20

    // Common pattern: atomic flag acquisition
    var acquired = std.atomic.Value(bool).init(false);
    const was_acquired = acquired.swap(true, .acquire);
    if (!was_acquired) {
  std.debug.print("Successfully acquired flag\n", .{});
  defer acquired.store(false, .release);
    }
}
```

------

## Compare-And-Swap Functions

### `pub inline fn cmpxchgStrong(self: *Self, expected_value: T, new_value: T, comptime success_order: AtomicOrder, comptime fail_order: AtomicOrder) ?T`

Atomically compares the current value with `expected_value`. If equal, stores `new_value` and returns `null`. Otherwise, returns the current value.

**Strong vs Weak:** Strong version never spuriously fails - if values are equal, the exchange always succeeds. Prefer this unless you're already in a retry loop.

**Parameters:**
- `expected_value` - Expected current value
- `new_value` - Value to store if comparison succeeds
- `success_order` - Memory ordering if comparison succeeds
- `fail_order` - Memory ordering if comparison fails (must be weaker than `success_order`)

**Returns:**
- `null` if the swap succeeded (value was `expected_value`)
- `?T` containing the actual current value if swap failed

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var value = std.atomic.Value(i32).init(10);

    // Try to change 10 to 20
    const result1 = value.cmpxchgStrong(10, 20, .seq_cst, .seq_cst);
    if (result1 == null) {
  std.debug.print("Successfully changed 10 to 20\n", .{});
    }

    // Try to change 10 to 30 (will fail because value is now 20)
    const result2 = value.cmpxchgStrong(10, 30, .seq_cst, .seq_cst);
    if (result2) |actual| {
  std.debug.print("Failed - value was {} not 10\n", .{actual});
    }

    // Lock-free stack push pattern
    var head = std.atomic.Value(?*Node).init(null);
    var node = Node{ .next = null, .data = 42 };

    while (true) {
  const current_head = head.load(.monotonic);
  node.next = current_head;
  if (head.cmpxchgStrong(current_head, &node, .release, .monotonic) == null) {
      break; // Successfully pushed
  }
  // Retry - another thread modified head
    }
}

const Node = struct {
    next: ?*Node,
    data: i32,
};
```

------

### `pub inline fn cmpxchgWeak(self: *Self, expected_value: T, new_value: T, comptime success_order: AtomicOrder, comptime fail_order: AtomicOrder) ?T`

Like `cmpxchgStrong`, but may spuriously fail even when the values are equal. Faster on some architectures.

**When to use:** Inside a loop that will retry anyway. On ARM and other architectures, weak CAS can be significantly faster.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var value = std.atomic.Value(usize).init(0);

    // Weak CAS in a retry loop (idiomatic usage)
    while (value.cmpxchgWeak(0, 1, .seq_cst, .seq_cst) != null) {
  // Spurious failures are okay - we'll just retry
  std.atomic.spinLoopHint();
    }

    std.debug.print("Value is now 1\n", .{});
}
```

------

## Arithmetic Functions

All arithmetic functions return the **previous** value before the operation.

### `pub inline fn fetchAdd(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically adds `operand` to the current value.

**Parameters:**
- `operand` - Value to add
- `order` - Memory ordering

**Returns:** Previous value (before addition)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var counter = std.atomic.Value(usize).init(10);

    const old = counter.fetchAdd(5, .monotonic);
    std.debug.print("Old: {}, New: {}\n", .{old, counter.load(.monotonic)});
    // Output: Old: 10, New: 15

    // Increment returns old value
    const prev = counter.fetchAdd(1, .monotonic);
    std.debug.print("Previous: {}, Current: {}\n", .{prev, counter.load(.monotonic)});
    // Output: Previous: 15, Current: 16
}
```

------

### `pub inline fn fetchSub(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically subtracts `operand` from the current value.

**Returns:** Previous value (before subtraction)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var counter = std.atomic.Value(usize).init(10);

    const old = counter.fetchSub(3, .monotonic);
    std.debug.print("Old: {}, New: {}\n", .{old, counter.load(.monotonic)});
    // Output: Old: 10, New: 7

    // Reference counting pattern
    if (counter.fetchSub(1, .release) == 1) {
  // We were the last reference (count was 1, now 0)
  std.debug.print("Last reference - cleanup time\n", .{});
    }
}
```

------

### `pub inline fn fetchMin(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically sets the value to the minimum of current value and `operand`.

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var min_val = std.atomic.Value(i32).init(100);

    _ = min_val.fetchMin(50, .seq_cst);
    std.debug.print("After min(100, 50): {}\n", .{min_val.load(.monotonic)});  // 50

    _ = min_val.fetchMin(75, .seq_cst);
    std.debug.print("After min(50, 75): {}\n", .{min_val.load(.monotonic)});   // 50

    _ = min_val.fetchMin(25, .seq_cst);
    std.debug.print("After min(50, 25): {}\n", .{min_val.load(.monotonic)});   // 25
}
```

------

### `pub inline fn fetchMax(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically sets the value to the maximum of current value and `operand`.

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var max_val = std.atomic.Value(i32).init(10);

    _ = max_val.fetchMax(50, .seq_cst);
    std.debug.print("After max(10, 50): {}\n", .{max_val.load(.monotonic)});  // 50

    _ = max_val.fetchMax(25, .seq_cst);
    std.debug.print("After max(50, 25): {}\n", .{max_val.load(.monotonic)});  // 50

    _ = max_val.fetchMax(100, .seq_cst);
    std.debug.print("After max(50, 100): {}\n", .{max_val.load(.monotonic)}); // 100
}
```

------

## Bitwise Functions

### `pub inline fn fetchAnd(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically performs bitwise AND with `operand`.

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var flags = std.atomic.Value(u8).init(0b11111111);

    _ = flags.fetchAnd(0b11110000, .seq_cst);
    std.debug.print("After AND: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    // Output: After AND: 0b11110000
}
```

------

### `pub inline fn fetchOr(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically performs bitwise OR with `operand`.

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var flags = std.atomic.Value(u8).init(0b00001111);

    _ = flags.fetchOr(0b11110000, .seq_cst);
    std.debug.print("After OR: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    // Output: After OR: 0b11111111
}
```

------

### `pub inline fn fetchXor(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically performs bitwise XOR with `operand`.

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var value = std.atomic.Value(u8).init(0b10101010);

    _ = value.fetchXor(0b11111111, .seq_cst);
    std.debug.print("After XOR: 0b{b:0>8}\n", .{value.load(.monotonic)});
    // Output: After XOR: 0b01010101 (flipped all bits)
}
```

------

### `pub inline fn fetchNand(self: *Self, operand: T, comptime order: AtomicOrder) T`

Atomically performs bitwise NAND (NOT (a AND b)).

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var value = std.atomic.Value(u8).init(0b11001100);

    const old = value.fetchNand(0b11110000, .seq_cst);
    const new = value.load(.monotonic);
    std.debug.print("NAND result: 0b{b:0>8}\n", .{new});
    // ~(0b11001100 & 0b11110000) = ~0b11000000 = 0b00111111
}
```

------

### `pub inline fn bitSet(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`

Atomically sets a specific bit to 1.

**Parameters:**
- `bit` - Bit index to set (0 = LSB)
- `order` - Memory ordering

**Returns:** Previous value of that bit (0 or 1)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var flags = std.atomic.Value(u32).init(0);

    const was_set = flags.bitSet(5, .seq_cst);
    std.debug.print("Bit 5 was {}, now set\n", .{was_set});

    const already_set = flags.bitSet(5, .seq_cst);
    std.debug.print("Bit 5 was already {}\n", .{already_set});  // 1

    std.debug.print("Flags: 0b{b}\n", .{flags.load(.monotonic)});  // 0b100000
}
```

------

### `pub inline fn bitReset(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`

Atomically sets a specific bit to 0.

**Returns:** Previous value of that bit (0 or 1)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var flags = std.atomic.Value(u32).init(0b11111111);

    const was_set = flags.bitReset(3, .seq_cst);
    std.debug.print("Bit 3 was {}, now cleared\n", .{was_set});  // 1

    std.debug.print("Flags: 0b{b:0>8}\n", .{flags.load(.monotonic)});  // 0b11110111
}
```

------

### `pub inline fn bitToggle(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`

Atomically toggles a specific bit (0→1 or 1→0).

**Returns:** Previous value of that bit (0 or 1)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var flags = std.atomic.Value(u8).init(0b10101010);

    _ = flags.bitToggle(0, .seq_cst);  // Toggle LSB
    std.debug.print("After toggle: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    // Output: 0b10101011

    _ = flags.bitToggle(0, .seq_cst);  // Toggle again
    std.debug.print("After toggle: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    // Output: 0b10101010 (back to original)
}
```

------

### `pub inline fn rmw(self: *Self, comptime op: std.builtin.AtomicRmwOp, operand: T, comptime order: AtomicOrder) T`

Generic read-modify-write operation. Allows specifying the operation via enum.

**Parameters:**
- `op` - Operation to perform (`.Add`, `.Sub`, `.Xchg`, `.And`, `.Or`, `.Xor`, `.Max`, `.Min`, `.Nand`)
- `operand` - Operand for the operation
- `order` - Memory ordering

**Returns:** Previous value

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    var value = std.atomic.Value(i32).init(10);

    // Equivalent to fetchAdd(5, .seq_cst)
    const old = value.rmw(.Add, 5, .seq_cst);
    std.debug.print("Old: {}, New: {}\n", .{old, value.load(.monotonic)});

    // Equivalent to swap(20, .seq_cst)
    _ = value.rmw(.Xchg, 20, .seq_cst);
}
```

------

## Utility Functions

### `pub inline fn spinLoopHint() void`

Signals to the processor that the caller is inside a busy-wait spin-loop. This allows the CPU to save power and share resources with other hardware threads.

**Use case:** Call inside tight loops waiting for atomic conditions to change.

**Architecture-specific:**
- x86/x86_64: Emits `pause` instruction
- ARM: Emits `isb` or `yield`
- PowerPC: Emits `or 27,27,27`
- RISC-V: Emits `pause` (if supported)

**Example:**
```zig
const std = @import("std");

pub fn waitForFlag(flag: *std.atomic.Value(bool)) void {
    while (!flag.load(.acquire)) {
  std.atomic.spinLoopHint();  // Be nice to CPU and other threads
    }
}

pub fn main() void {
    var ready = std.atomic.Value(bool).init(false);

    // Busy-wait with CPU hint
    while (!ready.load(.acquire)) {
  std.atomic.spinLoopHint();
    }
}
```

------

### `pub fn cacheLineForCpu(cpu: std.Target.Cpu) u16`

Returns the estimated cache line size in bytes for the given CPU architecture.

**Parameters:**
- `cpu` - Target CPU

**Returns:** Cache line size in bytes

**Example:**
```zig
const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    const size = std.atomic.cacheLineForCpu(builtin.cpu);
    std.debug.print("Cache line size: {} bytes\n", .{size});

    // Common values:
    // - x86_64, aarch64: 128 bytes
    // - ARM, MIPS, SPARC: 32 bytes
    // - Most others: 64 bytes
}
```

------

## Constants

### `pub const cache_line: comptime_int`

The estimated cache line size for the **current compilation target**. Use this to add padding between atomically-updated variables to prevent false sharing.

**False Sharing:** When two independent variables share a cache line, atomic updates to one invalidate the cache line for the other, causing performance degradation.

**Example:**
```zig
const std = @import("std");

// BAD: False sharing between threads
const BadCounters = struct {
    thread1_counter: std.atomic.Value(usize),
    thread2_counter: std.atomic.Value(usize),  // Likely shares cache line!
};

// GOOD: Prevent false sharing with padding
const GoodCounters = struct {
    thread1_counter: std.atomic.Value(usize),
    padding: [std.atomic.cache_line - @sizeOf(std.atomic.Value(usize))]u8 = undefined,
    thread2_counter: std.atomic.Value(usize),
};

// ALTERNATIVE: Align to cache line boundary
const AlignedCounter = struct {
    counter: std.atomic.Value(usize) align(std.atomic.cache_line),
};

pub fn main() void {
    std.debug.print("Cache line size: {}\n", .{std.atomic.cache_line});
}
```

------

## Usage Patterns

### Pattern 1: Reference Counting

```zig
const std = @import("std");

const RefCounted = struct {
    data: i32,
    ref_count: std.atomic.Value(usize),

    fn create(data: i32) RefCounted {
  return .{
      .data = data,
      .ref_count = std.atomic.Value(usize).init(1),
  };
    }

    fn retain(self: *RefCounted) void {
  _ = self.ref_count.fetchAdd(1, .monotonic);
    }

    fn release(self: *RefCounted) void {
  // Release ensures all uses happen-before count decrement
  if (self.ref_count.fetchSub(1, .release) == 1) {
      // Acquire synchronizes with all previous releases
      _ = self.ref_count.load(.acquire);
      self.destroy();
  }
    }

    fn destroy(self: *RefCounted) void {
  std.debug.print("Destroying object with data: {}\n", .{self.data});
    }
};

pub fn main() void {
    var obj = RefCounted.create(42);
    obj.retain();  // ref_count = 2
    obj.release(); // ref_count = 1
    obj.release(); // ref_count = 0, destroys object
}
```

------

### Pattern 2: Lock-Free Stack

```zig
const std = @import("std");

const Node = struct {
    next: ?*Node,
    value: i32,
};

const LockFreeStack = struct {
    head: std.atomic.Value(?*Node) = std.atomic.Value(?*Node).init(null),

    fn push(self: *LockFreeStack, node: *Node) void {
  while (true) {
      const current_head = self.head.load(.monotonic);
      node.next = current_head;

      // Try to swing head to new node
      if (self.head.cmpxchgWeak(current_head, node, .release, .monotonic) == null) {
          return;  // Success
      }
      // Retry - another thread modified head
  }
    }

    fn pop(self: *LockFreeStack) ?*Node {
  while (true) {
      const current_head = self.head.load(.acquire) orelse return null;
      const next = current_head.next;

      // Try to swing head to next
      if (self.head.cmpxchgWeak(current_head, next, .acquire, .monotonic) == null) {
          return current_head;  // Success
      }
      // Retry - another thread modified head
  }
    }
};

pub fn main() void {
    var stack = LockFreeStack{};
    var node1 = Node{ .next = null, .value = 10 };
    var node2 = Node{ .next = null, .value = 20 };

    stack.push(&node1);
    stack.push(&node2);

    if (stack.pop()) |n| {
  std.debug.print("Popped: {}\n", .{n.value});  // 20
    }
}
```

------

### Pattern 3: Spin Lock

```zig
const std = @import("std");

const SpinLock = struct {
    locked: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    fn lock(self: *SpinLock) void {
  while (self.locked.swap(true, .acquire)) {
      // Already locked, spin
      while (self.locked.load(.monotonic)) {
          std.atomic.spinLoopHint();
      }
  }
    }

    fn unlock(self: *SpinLock) void {
  self.locked.store(false, .release);
    }

    fn tryLock(self: *SpinLock) bool {
  return !self.locked.swap(true, .acquire);
    }
};

pub fn main() void {
    var lock = SpinLock{};

    lock.lock();
    defer lock.unlock();

    // Critical section
    std.debug.print("Inside critical section\n", .{});
}
```

------

### Pattern 4: Wait-Free Counter with Statistics

```zig
const std = @import("std");

const Counter = struct {
    value: std.atomic.Value(usize) align(std.atomic.cache_line),
    max_seen: std.atomic.Value(usize) align(std.atomic.cache_line),

    fn init() Counter {
  return .{
      .value = std.atomic.Value(usize).init(0),
      .max_seen = std.atomic.Value(usize).init(0),
  };
    }

    fn increment(self: *Counter) usize {
  const new_val = self.value.fetchAdd(1, .monotonic) + 1;

  // Update max if needed
  while (true) {
      const current_max = self.max_seen.load(.monotonic);
      if (new_val <= current_max) break;

      if (self.max_seen.cmpxchgWeak(current_max, new_val, .monotonic, .monotonic) == null) {
          break;
      }
  }

  return new_val;
    }

    fn get(self: *const Counter) usize {
  return self.value.load(.monotonic);
    }

    fn getMax(self: *const Counter) usize {
  return self.max_seen.load(.monotonic);
    }
};

pub fn main() void {
    var counter = Counter.init();

    _ = counter.increment();  // 1
    _ = counter.increment();  // 2
    _ = counter.increment();  // 3

    std.debug.print("Current: {}, Max: {}\n", .{counter.get(), counter.getMax()});
}
```

------

### Pattern 5: Producer-Consumer Flag

```zig
const std = @import("std");

const SharedData = struct {
    value: i32 = 0,
    ready: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
};

fn producer(data: *SharedData) void {
    // Produce data
    data.value = 42;

    // Signal ready with release (publishes data.value)
    data.ready.store(true, .release);
}

fn consumer(data: *SharedData) void {
    // Wait for ready with acquire (synchronizes with release)
    while (!data.ready.load(.acquire)) {
  std.atomic.spinLoopHint();
    }

    // Safe to read data.value
    std.debug.print("Consumed: {}\n", .{data.value});
}

pub fn main() void {
    var data = SharedData{};

    producer(&data);
    consumer(&data);
}
```

------

## Error Sets

`std.atomic` does not define any error sets. All operations are infallible.

------

## Debug Checklist

✅ **Memory ordering is appropriate for the use case** - Don't use `.monotonic` for synchronization, don't overuse `.seq_cst`

✅ **Compare-and-swap loops have spinLoopHint()** - Prevent CPU resource waste in busy-wait loops

✅ **Acquire-release pairs match** - Every `.release` store should have corresponding `.acquire` load

✅ **No direct access to `.raw` field** - Use atomic methods instead to prevent data races

✅ **False sharing is prevented for hot atomics** - Add padding or alignment for frequently-updated atomics accessed by different threads

✅ **CAS return value is checked** - `cmpxchg` returns `null` on success, `?T` on failure - don't ignore the result

✅ **Fetch operations return old value** - `fetchAdd(5)` returns the value **before** adding 5, not after

✅ **Types are suitable for atomics** - Only primitive types (integers, floats, bools, pointers, enums) can be used with `Value(T)`

✅ **Fail ordering is not stronger than success ordering** - In CAS, `fail_order` must be `.monotonic`, `.acquire`, or `.seq_cst` if `success_order` is `.seq_cst`

✅ **No UB from relaxed atomics** - Even with `.monotonic`, individual operations are atomic - no torn reads/writes

------

## Performance Tips

1. **Use the weakest memory ordering that provides required guarantees** - `.monotonic` is much faster than `.seq_cst` on weakly-ordered architectures (ARM, POWER). Use `.seq_cst` only when you need total ordering across all operations.

2. **Prefer `cmpxchgWeak` in loops** - On ARM and similar architectures, weak CAS can be 2-3x faster than strong. Always use weak in retry loops:
   ```zig
   while (value.cmpxchgWeak(old, new, .seq_cst, .seq_cst) != null) {
 // Retry
   }
   ```

3. **Add padding to prevent false sharing** - Independent atomics updated by different threads should be on separate cache lines:
   ```zig
   counter1: std.atomic.Value(usize) align(std.atomic.cache_line),
   ```

4. **Use `spinLoopHint()` in busy-wait loops** - Dramatically reduces power consumption and improves performance on SMT (hyperthreading) systems:
   ```zig
   while (flag.load(.acquire)) {
 std.atomic.spinLoopHint();
   }
   ```

5. **Batch operations when possible** - Update local variables, then write atomically once rather than multiple atomic operations:
   ```zig
   // Bad: 3 atomic operations
   counter.fetchAdd(1, .monotonic);
   counter.fetchAdd(1, .monotonic);
   counter.fetchAdd(1, .monotonic);

   // Good: 1 atomic operation
   counter.fetchAdd(3, .monotonic);
   ```

6. **Consider using fetch operations for simple counters** - `fetchAdd` is often faster than CAS loops for simple increments

7. **Profile before optimizing ordering** - On x86_64, `.monotonic` and `.seq_cst` have similar cost. On ARM/POWER, there's a huge difference. Profile on your target platform.

8. **Align hot atomics to cache line boundaries** - Ensures the entire atomic fits in one cache line, preventing split loads/stores

9. **Use atomic bit operations for flags** - `bitSet`, `bitReset`, `bitToggle` can be faster than `fetchOr`/`fetchAnd` when the bit position is comptime-known

------

## See Also

- **std.Thread** - Higher-level threading primitives (Mutex, RwLock, Semaphore, etc.)
- **std.Thread.Mutex** - Blocking mutex built on atomics
- **std.Thread.Futex** - Low-level futex-based waiting (uses atomics)
- **std.builtin.AtomicOrder** - Memory ordering enum documentation
- **std.builtin.AtomicRmwOp** - Read-modify-write operation enum

**External Resources:**
- [C11 Memory Model](https://en.cppreference.com/w/c/atomic/memory_order) - Zig uses the same model
- [Preshing on Programming: Memory Ordering](https://preshing.com/20120913/acquire-and-release-semantics/)
- [1024cores: Lock-Free Algorithms](http://www.1024cores.net/home/lock-free-algorithms)
