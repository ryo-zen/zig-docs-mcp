# std.atomic.Value(T)

Thread-safe atomic wrapper type for lock-free concurrent programming.

## Overview

`std.atomic.Value(T)` is a generic wrapper that makes a primitive value thread-safe by enforcing atomic access. It prevents data races by requiring all reads and writes to go through atomic operations with explicit memory ordering.

**Type Parameter:**
- `T` - Must be a primitive type suitable for atomic operations (integers, floats, bools, pointers, enums)

**Key Characteristics:**
- **Type-safe**: Prevents accidental non-atomic access to shared data
- **Zero-cost**: Compiles directly to CPU atomic instructions
- **Explicit memory ordering**: Every operation requires specifying synchronization semantics
- **Generic**: Works with any atomically-supported primitive type
- **Cross-platform**: Uniform API across all architectures

## Quick Example

```zig
const std = @import("std");

pub fn main() void {
    // Create atomic counter
    var counter = std.atomic.Value(usize).init(0);

    // Atomic increment
    const old = counter.fetchAdd(1, .monotonic);
    std.debug.print("Old: {}, New: {}\n", .{old, counter.load(.monotonic)});

    // Atomic compare-and-swap
    const result = counter.cmpxchgStrong(1, 100, .seq_cst, .seq_cst);
    if (result == null) {
        std.debug.print("Successfully changed to 100\n", .{});
    }
}
```

## Supported Types

**Integer types:** `u8`, `i8`, `u16`, `i16`, `u32`, `i32`, `u64`, `i64`, `u128`, `i128`, `usize`, `isize`

**Float types:** `f16`, `f32`, `f64`, `f128`

**Boolean:** `bool`

**Pointer types:** `?*T`, `*T`, `[*]T`

**Enum types:** Any enum with integer backing

**Example:**
```zig
var int_atomic = std.atomic.Value(u32).init(42);
var float_atomic = std.atomic.Value(f64).init(3.14);
var bool_atomic = std.atomic.Value(bool).init(false);
var ptr_atomic = std.atomic.Value(?*Node).init(null);

const Status = enum { idle, running, done };
var enum_atomic = std.atomic.Value(Status).init(.idle);
```

## Fields

### `raw: T`

The underlying primitive value.

**⚠️ Warning:** Direct access to `raw` bypasses atomic operations and can cause data races. Always use the atomic methods (`load`, `store`, `fetchAdd`, etc.) for thread-safe access.

**Safe access (non-atomic) scenarios:**
- Single-threaded initialization before publishing to other threads
- After all synchronization is complete (e.g., after joining all threads)
- Debug inspection in controlled environments

**Example:**
```zig
var value = std.atomic.Value(usize).init(10);

// WRONG - Data race if accessed by multiple threads!
value.raw += 1;  // ❌

// CORRECT - Atomic operation
_ = value.fetchAdd(1, .monotonic);  // ✅
```

## Core Operations

### Creation

**`pub fn init(value: T) Self`**

Creates a new atomic value. This is the only way to construct a `Value(T)`.

```zig
var counter = std.atomic.Value(usize).init(0);
var flag = std.atomic.Value(bool).init(false);
var ptr = std.atomic.Value(?*Data).init(null);
```

### Load/Store

**`pub inline fn load(self: *const Self, comptime order: AtomicOrder) T`**

Atomically reads the current value.

**Memory orderings:** `.unordered`, `.monotonic`, `.acquire`, `.seq_cst`

```zig
const value = counter.load(.monotonic);  // Simple read
const value = counter.load(.acquire);    // Synchronize with releases
```

**`pub inline fn store(self: *Self, value: T, comptime order: AtomicOrder) void`**

Atomically writes a new value.

**Memory orderings:** `.unordered`, `.monotonic`, `.release`, `.seq_cst`

```zig
counter.store(42, .monotonic);  // Simple write
counter.store(99, .release);    // Publish data to other threads
```

### Swap

**`pub inline fn swap(self: *Self, operand: T, comptime order: AtomicOrder) T`**

Atomically replaces the value and returns the old value.

```zig
const old = counter.swap(new_value, .seq_cst);
std.debug.print("Swapped {} for {}\n", .{old, new_value});
```

## Compare-And-Swap

### `cmpxchgStrong`

**`pub inline fn cmpxchgStrong(self: *Self, expected_value: T, new_value: T, comptime success_order: AtomicOrder, comptime fail_order: AtomicOrder) ?T`**

Atomically compares current value with `expected_value`. If equal, stores `new_value` and returns `null`. Otherwise, returns the actual current value.

**Never spuriously fails** - if values match, the exchange always succeeds.

**Returns:**
- `null` - Swap succeeded
- `?T` - Swap failed, contains actual current value

```zig
var value = std.atomic.Value(i32).init(10);

// Try to change 10 to 20
if (value.cmpxchgStrong(10, 20, .seq_cst, .seq_cst) == null) {
    std.debug.print("Success\n", .{});
} else {
    std.debug.print("Failed - value wasn't 10\n", .{});
}
```

### `cmpxchgWeak`

**`pub inline fn cmpxchgWeak(self: *Self, expected_value: T, new_value: T, comptime success_order: AtomicOrder, comptime fail_order: AtomicOrder) ?T`**

Like `cmpxchgStrong` but **may spuriously fail** even when values match. Faster on ARM and similar architectures.

**Use in retry loops:**

```zig
var value = std.atomic.Value(usize).init(0);

// Retry until successful
while (value.cmpxchgWeak(0, 1, .seq_cst, .seq_cst) != null) {
    std.atomic.spinLoopHint();
}
```

## Arithmetic Operations

All arithmetic operations return the **previous value** before the operation.

### `fetchAdd`
**`pub inline fn fetchAdd(self: *Self, operand: T, comptime order: AtomicOrder) T`**

Atomically adds `operand` to the current value.

```zig
var counter = std.atomic.Value(usize).init(10);
const old = counter.fetchAdd(5, .monotonic);  // old = 10, counter = 15
```

### `fetchSub`
**`pub inline fn fetchSub(self: *Self, operand: T, comptime order: AtomicOrder) T`**

Atomically subtracts `operand` from the current value.

```zig
var counter = std.atomic.Value(usize).init(10);
const old = counter.fetchSub(3, .monotonic);  // old = 10, counter = 7
```

### `fetchMin` / `fetchMax`
**`pub inline fn fetchMin(self: *Self, operand: T, comptime order: AtomicOrder) T`**
**`pub inline fn fetchMax(self: *Self, operand: T, comptime order: AtomicOrder) T`**

Atomically updates to the minimum/maximum of current value and operand.

```zig
var min_val = std.atomic.Value(i32).init(100);
_ = min_val.fetchMin(50, .seq_cst);  // min_val = 50
_ = min_val.fetchMin(75, .seq_cst);  // min_val = 50 (unchanged)

var max_val = std.atomic.Value(i32).init(10);
_ = max_val.fetchMax(50, .seq_cst);  // max_val = 50
```

## Bitwise Operations

All bitwise operations return the **previous value** before the operation.

### `fetchAnd` / `fetchOr` / `fetchXor` / `fetchNand`

**`pub inline fn fetchAnd(self: *Self, operand: T, comptime order: AtomicOrder) T`**
**`pub inline fn fetchOr(self: *Self, operand: T, comptime order: AtomicOrder) T`**
**`pub inline fn fetchXor(self: *Self, operand: T, comptime order: AtomicOrder) T`**
**`pub inline fn fetchNand(self: *Self, operand: T, comptime order: AtomicOrder) T`**

Atomically performs bitwise AND, OR, XOR, or NAND with operand.

```zig
var flags = std.atomic.Value(u8).init(0b11111111);

_ = flags.fetchAnd(0b11110000, .seq_cst);  // Clear lower 4 bits
_ = flags.fetchOr(0b00001111, .seq_cst);   // Set lower 4 bits
_ = flags.fetchXor(0b11111111, .seq_cst);  // Flip all bits
```

### Bit Manipulation

**`pub inline fn bitSet(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`**
**`pub inline fn bitReset(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`**
**`pub inline fn bitToggle(self: *Self, bit: Bit, comptime order: AtomicOrder) u1`**

Atomically sets, clears, or toggles a specific bit. Returns the **previous value** of that bit (0 or 1).

**Type:** `Bit = std.math.Log2Int(T)` - the bit index type for `T`

**Optimized:** If `bit` is comptime-known, may compile to efficient single-instruction bit operations.

```zig
var flags = std.atomic.Value(u32).init(0);

const was_set = flags.bitSet(5, .seq_cst);      // Set bit 5, returns 0
const already = flags.bitSet(5, .seq_cst);      // Set again, returns 1

_ = flags.bitReset(5, .seq_cst);                // Clear bit 5
_ = flags.bitToggle(3, .seq_cst);               // Toggle bit 3
```

## Generic RMW

**`pub inline fn rmw(self: *Self, comptime op: std.builtin.AtomicRmwOp, operand: T, comptime order: AtomicOrder) T`**

Generic read-modify-write operation using an enum to specify the operation.

**Operations:** `.Add`, `.Sub`, `.Xchg`, `.And`, `.Or`, `.Xor`, `.Max`, `.Min`, `.Nand`

```zig
var value = std.atomic.Value(i32).init(10);

// Equivalent to fetchAdd(5, .seq_cst)
const old = value.rmw(.Add, 5, .seq_cst);

// Equivalent to swap(20, .seq_cst)
_ = value.rmw(.Xchg, 20, .seq_cst);
```

## Memory Ordering Guidelines

### For Simple Counters (No Synchronization Needed)

Use `.monotonic` - fastest, ensures atomic operations but no cross-thread synchronization.

```zig
var stats_counter = std.atomic.Value(usize).init(0);
_ = stats_counter.fetchAdd(1, .monotonic);  // Just count, no sync needed
```

### For Locks/Flags (Synchronization Required)

Use `.acquire` for loads, `.release` for stores.

```zig
// Acquire lock
while (lock.swap(true, .acquire)) {
    std.atomic.spinLoopHint();
}

// Release lock
lock.store(false, .release);
```

### For Complex Synchronization

Use `.seq_cst` for total ordering across all operations.

```zig
// Ensures all threads see operations in the same order
value.store(42, .seq_cst);
```

## Common Patterns

### Reference Counting

```zig
const RefCount = struct {
    count: std.atomic.Value(usize),

    fn init() RefCount {
        return .{ .count = std.atomic.Value(usize).init(1) };
    }

    fn retain(self: *RefCount) void {
        _ = self.count.fetchAdd(1, .monotonic);
    }

    fn release(self: *RefCount) bool {
        if (self.count.fetchSub(1, .release) == 1) {
            _ = self.count.load(.acquire);  // Sync with other releases
            return true;  // Last reference
        }
        return false;
    }
};
```

### Lock-Free Flag

```zig
var ready_flag = std.atomic.Value(bool).init(false);

// Producer
data.value = compute();
ready_flag.store(true, .release);

// Consumer
while (!ready_flag.load(.acquire)) {
    std.atomic.spinLoopHint();
}
use(data.value);  // Safe - synchronized
```

### CAS Loop for Lock-Free Update

```zig
var shared_max = std.atomic.Value(i32).init(0);

fn updateMax(new_value: i32) void {
    while (true) {
        const current = shared_max.load(.monotonic);
        if (new_value <= current) return;  // Already larger

        if (shared_max.cmpxchgWeak(current, new_value, .release, .monotonic) == null) {
            return;  // Success
        }
        // Retry - another thread updated it
    }
}
```

## See Also

- **[std.atomic](std.atomic.md)** - Main atomic namespace documentation with all functions and usage patterns
- **std.Thread.Mutex** - Higher-level blocking mutex built on atomics
- **std.builtin.AtomicOrder** - Memory ordering semantics
- **std.builtin.AtomicRmwOp** - Read-modify-write operations enum
