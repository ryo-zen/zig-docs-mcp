// Comprehensive test examples for std.atomic documentation
// Run with: zig test atomic.tests.zig

const std = @import("std");
const testing = std.testing;

// ============================================================================
// Basic Value Creation and Operations
// ============================================================================

test "atomic Value initialization" {
    std.debug.print("\n=== Atomic Value Initialization ===\n", .{});

    var int_atomic = std.atomic.Value(u32).init(42);
    var float_atomic = std.atomic.Value(f64).init(3.14);
    var bool_atomic = std.atomic.Value(bool).init(false);
    var ptr_atomic = std.atomic.Value(?*u8).init(null);

    try testing.expectEqual(@as(u32, 42), int_atomic.load(.monotonic));
    try testing.expectEqual(@as(f64, 3.14), float_atomic.load(.monotonic));
    try testing.expectEqual(false, bool_atomic.load(.monotonic));
    try testing.expectEqual(@as(?*u8, null), ptr_atomic.load(.monotonic));

    std.debug.print("  ✅ PASS - All types initialized correctly\n\n", .{});
}

test "atomic load and store" {
    std.debug.print("=== Load and Store ===\n", .{});

    var counter = std.atomic.Value(usize).init(100);

    const value = counter.load(.monotonic);
    std.debug.print("  Loaded value: {}\n", .{value});
    try testing.expectEqual(@as(usize, 100), value);

    counter.store(200, .monotonic);
    std.debug.print("  Stored 200, now: {}\n", .{counter.load(.monotonic)});
    try testing.expectEqual(@as(usize, 200), counter.load(.monotonic));

    // Test with release/acquire for synchronization
    counter.store(999, .release);
    const synced = counter.load(.acquire);
    try testing.expectEqual(@as(usize, 999), synced);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "atomic swap" {
    std.debug.print("=== Swap Operation ===\n", .{});

    var value = std.atomic.Value(i32).init(10);

    const old = value.swap(20, .seq_cst);
    std.debug.print("  Swapped: old={}, new={}\n", .{ old, value.load(.monotonic) });

    try testing.expectEqual(@as(i32, 10), old);
    try testing.expectEqual(@as(i32, 20), value.load(.monotonic));

    // Flag acquisition pattern
    var flag = std.atomic.Value(bool).init(false);
    const was_acquired = flag.swap(true, .acquire);
    try testing.expectEqual(false, was_acquired);
    try testing.expectEqual(true, flag.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Compare-And-Swap
// ============================================================================

test "cmpxchgStrong success and failure" {
    std.debug.print("=== Compare-And-Swap Strong ===\n", .{});

    var value = std.atomic.Value(i32).init(10);

    // Success case
    const result1 = value.cmpxchgStrong(10, 20, .seq_cst, .seq_cst);
    std.debug.print("  CAS(10→20): {s}\n", .{if (result1 == null) "SUCCESS" else "FAILED"});
    try testing.expectEqual(@as(?i32, null), result1);
    try testing.expectEqual(@as(i32, 20), value.load(.monotonic));

    // Failure case
    const result2 = value.cmpxchgStrong(10, 30, .seq_cst, .seq_cst);
    std.debug.print("  CAS(10→30): {s} (value was {})\n", .{
        if (result2 == null) "SUCCESS" else "FAILED",
        if (result2) |v| v else 0,
    });
    try testing.expect(result2 != null);
    try testing.expectEqual(@as(i32, 20), result2.?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "cmpxchgWeak in retry loop" {
    std.debug.print("=== Compare-And-Swap Weak (Retry Loop) ===\n", .{});

    var value = std.atomic.Value(usize).init(0);
    var attempts: usize = 0;

    // Weak CAS may spuriously fail, so loop until success
    while (value.cmpxchgWeak(0, 1, .seq_cst, .seq_cst) != null) {
        attempts += 1;
        std.atomic.spinLoopHint();
    }

    std.debug.print("  Changed 0→1 after {} attempts\n", .{attempts + 1});
    try testing.expectEqual(@as(usize, 1), value.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Arithmetic Operations
// ============================================================================

test "fetchAdd and fetchSub" {
    std.debug.print("=== Fetch Add/Sub ===\n", .{});

    var counter = std.atomic.Value(usize).init(10);

    const old_add = counter.fetchAdd(5, .monotonic);
    std.debug.print("  fetchAdd(5): old={}, new={}\n", .{ old_add, counter.load(.monotonic) });
    try testing.expectEqual(@as(usize, 10), old_add);
    try testing.expectEqual(@as(usize, 15), counter.load(.monotonic));

    const old_sub = counter.fetchSub(3, .monotonic);
    std.debug.print("  fetchSub(3): old={}, new={}\n", .{ old_sub, counter.load(.monotonic) });
    try testing.expectEqual(@as(usize, 15), old_sub);
    try testing.expectEqual(@as(usize, 12), counter.load(.monotonic));

    // Wrapping behavior
    counter.store(0, .monotonic);
    _ = counter.fetchSub(1, .monotonic);
    std.debug.print("  Underflow: {}\n", .{counter.load(.monotonic)});
    try testing.expectEqual(std.math.maxInt(usize), counter.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "fetchMin and fetchMax" {
    std.debug.print("=== Fetch Min/Max ===\n", .{});

    var min_val = std.atomic.Value(i32).init(100);
    _ = min_val.fetchMin(50, .seq_cst);
    std.debug.print("  min(100, 50) = {}\n", .{min_val.load(.monotonic)});
    try testing.expectEqual(@as(i32, 50), min_val.load(.monotonic));

    _ = min_val.fetchMin(75, .seq_cst);
    std.debug.print("  min(50, 75) = {}\n", .{min_val.load(.monotonic)});
    try testing.expectEqual(@as(i32, 50), min_val.load(.monotonic));

    var max_val = std.atomic.Value(i32).init(10);
    _ = max_val.fetchMax(50, .seq_cst);
    std.debug.print("  max(10, 50) = {}\n", .{max_val.load(.monotonic)});
    try testing.expectEqual(@as(i32, 50), max_val.load(.monotonic));

    _ = max_val.fetchMax(25, .seq_cst);
    std.debug.print("  max(50, 25) = {}\n", .{max_val.load(.monotonic)});
    try testing.expectEqual(@as(i32, 50), max_val.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Bitwise Operations
// ============================================================================

test "bitwise operations (fetchAnd, fetchOr, fetchXor)" {
    std.debug.print("=== Bitwise Operations ===\n", .{});

    var flags = std.atomic.Value(u8).init(0b11111111);

    _ = flags.fetchAnd(0b11110000, .seq_cst);
    std.debug.print("  AND 0b11110000: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    try testing.expectEqual(@as(u8, 0b11110000), flags.load(.monotonic));

    _ = flags.fetchOr(0b00001111, .seq_cst);
    std.debug.print("  OR 0b00001111:  0b{b:0>8}\n", .{flags.load(.monotonic)});
    try testing.expectEqual(@as(u8, 0b11111111), flags.load(.monotonic));

    _ = flags.fetchXor(0b10101010, .seq_cst);
    std.debug.print("  XOR 0b10101010: 0b{b:0>8}\n", .{flags.load(.monotonic)});
    try testing.expectEqual(@as(u8, 0b01010101), flags.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "bit manipulation (bitSet, bitReset, bitToggle)" {
    std.debug.print("=== Bit Manipulation ===\n", .{});

    var flags = std.atomic.Value(u32).init(0);

    const was_set = flags.bitSet(5, .seq_cst);
    std.debug.print("  bitSet(5): was={}, flags=0b{b}\n", .{ was_set, flags.load(.monotonic) });
    try testing.expectEqual(@as(u1, 0), was_set);
    try testing.expect((flags.load(.monotonic) & (1 << 5)) != 0);

    const already_set = flags.bitSet(5, .seq_cst);
    try testing.expectEqual(@as(u1, 1), already_set);

    _ = flags.bitReset(5, .seq_cst);
    std.debug.print("  bitReset(5): flags=0b{b}\n", .{flags.load(.monotonic)});
    try testing.expect((flags.load(.monotonic) & (1 << 5)) == 0);

    _ = flags.bitToggle(3, .seq_cst);
    std.debug.print("  bitToggle(3): flags=0b{b}\n", .{flags.load(.monotonic)});
    try testing.expect((flags.load(.monotonic) & (1 << 3)) != 0);

    _ = flags.bitToggle(3, .seq_cst);
    std.debug.print("  bitToggle(3): flags=0b{b}\n", .{flags.load(.monotonic)});
    try testing.expect((flags.load(.monotonic) & (1 << 3)) == 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Generic RMW
// ============================================================================

test "generic rmw operations" {
    std.debug.print("=== Generic RMW ===\n", .{});

    var value = std.atomic.Value(i32).init(10);

    const old_add = value.rmw(.Add, 5, .seq_cst);
    std.debug.print("  rmw(Add, 5): old={}, new={}\n", .{ old_add, value.load(.monotonic) });
    try testing.expectEqual(@as(i32, 10), old_add);
    try testing.expectEqual(@as(i32, 15), value.load(.monotonic));

    _ = value.rmw(.Xchg, 100, .seq_cst);
    std.debug.print("  rmw(Xchg, 100): new={}\n", .{value.load(.monotonic)});
    try testing.expectEqual(@as(i32, 100), value.load(.monotonic));

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "pattern: reference counting" {
    std.debug.print("=== Pattern: Reference Counting ===\n", .{});

    const RefCount = struct {
        count: std.atomic.Value(usize),

        fn init() @This() {
            return .{ .count = std.atomic.Value(usize).init(1) };
        }

        fn retain(self: *@This()) void {
            _ = self.count.fetchAdd(1, .monotonic);
            std.debug.print("  retain: count={}\n", .{self.count.load(.monotonic)});
        }

        fn release(self: *@This()) bool {
            const old = self.count.fetchSub(1, .release);
            std.debug.print("  release: old={}, new={}\n", .{ old, self.count.load(.monotonic) });

            if (old == 1) {
                _ = self.count.load(.acquire); // Sync with other releases
                return true; // Last reference
            }
            return false;
        }
    };

    var rc = RefCount.init();
    try testing.expectEqual(@as(usize, 1), rc.count.load(.monotonic));

    rc.retain(); // 1 → 2
    rc.retain(); // 2 → 3

    try testing.expectEqual(false, rc.release()); // 3 → 2
    try testing.expectEqual(false, rc.release()); // 2 → 1
    try testing.expectEqual(true, rc.release()); // 1 → 0 (last ref)

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "pattern: spin lock" {
    std.debug.print("=== Pattern: Spin Lock ===\n", .{});

    const SpinLock = struct {
        locked: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

        fn lock(self: *@This()) void {
            while (self.locked.swap(true, .acquire)) {
                while (self.locked.load(.monotonic)) {
                    std.atomic.spinLoopHint();
                }
            }
        }

        fn unlock(self: *@This()) void {
            self.locked.store(false, .release);
        }

        fn tryLock(self: *@This()) bool {
            return !self.locked.swap(true, .acquire);
        }
    };

    var lock = SpinLock{};

    // First lock should succeed
    lock.lock();
    std.debug.print("  Acquired lock\n", .{});
    try testing.expectEqual(true, lock.locked.load(.monotonic));

    // Try lock should fail
    const acquired = lock.tryLock();
    std.debug.print("  tryLock: {}\n", .{acquired});
    try testing.expectEqual(false, acquired);

    lock.unlock();
    std.debug.print("  Released lock\n", .{});
    try testing.expectEqual(false, lock.locked.load(.monotonic));

    // Try lock should now succeed
    try testing.expectEqual(true, lock.tryLock());
    lock.unlock();

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "pattern: lock-free stack push/pop" {
    std.debug.print("=== Pattern: Lock-Free Stack ===\n", .{});

    const Node = struct {
        next: ?*@This(),
        value: i32,
    };

    const LockFreeStack = struct {
        head: std.atomic.Value(?*Node) = std.atomic.Value(?*Node).init(null),

        fn push(self: *@This(), node: *Node) void {
            while (true) {
                const current_head = self.head.load(.monotonic);
                node.next = current_head;

                if (self.head.cmpxchgWeak(current_head, node, .release, .monotonic) == null) {
                    return; // Success
                }
                // Retry
            }
        }

        fn pop(self: *@This()) ?*Node {
            while (true) {
                const current_head = self.head.load(.acquire) orelse return null;
                const next = current_head.next;

                if (self.head.cmpxchgWeak(current_head, next, .acquire, .monotonic) == null) {
                    return current_head; // Success
                }
                // Retry
            }
        }
    };

    var stack = LockFreeStack{};
    var node1 = Node{ .next = null, .value = 10 };
    var node2 = Node{ .next = null, .value = 20 };
    var node3 = Node{ .next = null, .value = 30 };

    stack.push(&node1);
    std.debug.print("  Pushed {}\n", .{node1.value});
    stack.push(&node2);
    std.debug.print("  Pushed {}\n", .{node2.value});
    stack.push(&node3);
    std.debug.print("  Pushed {}\n", .{node3.value});

    const popped1 = stack.pop();
    try testing.expect(popped1 != null);
    std.debug.print("  Popped {}\n", .{popped1.?.value});
    try testing.expectEqual(@as(i32, 30), popped1.?.value);

    const popped2 = stack.pop();
    try testing.expect(popped2 != null);
    std.debug.print("  Popped {}\n", .{popped2.?.value});
    try testing.expectEqual(@as(i32, 20), popped2.?.value);

    const popped3 = stack.pop();
    try testing.expect(popped3 != null);
    std.debug.print("  Popped {}\n", .{popped3.?.value});
    try testing.expectEqual(@as(i32, 10), popped3.?.value);

    const empty = stack.pop();
    try testing.expectEqual(@as(?*Node, null), empty);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "pattern: producer-consumer flag" {
    std.debug.print("=== Pattern: Producer-Consumer Flag ===\n", .{});

    const SharedData = struct {
        value: i32 = 0,
        ready: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    };

    var data = SharedData{};

    // Producer
    data.value = 42;
    data.ready.store(true, .release);
    std.debug.print("  Producer: set value=42, signaled ready\n", .{});

    // Consumer
    var spin_count: usize = 0;
    while (!data.ready.load(.acquire)) {
        std.atomic.spinLoopHint();
        spin_count += 1;
    }
    std.debug.print("  Consumer: ready flag observed (spins={})\n", .{spin_count});

    try testing.expectEqual(@as(i32, 42), data.value);
    std.debug.print("  Consumer: read value={}\n", .{data.value});

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Utility Functions
// ============================================================================

test "spinLoopHint" {
    std.debug.print("=== Spin Loop Hint ===\n", .{});

    var flag = std.atomic.Value(bool).init(true);
    var iterations: usize = 0;

    // Simulate busy-wait (immediately set to false to exit)
    flag.store(false, .release);

    while (flag.load(.acquire)) {
        std.atomic.spinLoopHint();
        iterations += 1;
    }

    std.debug.print("  spinLoopHint called {} times\n", .{iterations});
    std.debug.print("  ✅ PASS\n\n", .{});
}

test "cache_line constant" {
    std.debug.print("=== Cache Line Size ===\n", .{});

    const size = std.atomic.cache_line;
    std.debug.print("  Cache line size: {} bytes\n", .{size});

    // Should be a reasonable cache line size
    try testing.expect(size >= 16);
    try testing.expect(size <= 256);

    // Should be power of 2
    try testing.expect((size & (size - 1)) == 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "prevent false sharing with padding" {
    std.debug.print("=== False Sharing Prevention ===\n", .{});

    const AlignedCounter = struct {
        counter: std.atomic.Value(usize) align(std.atomic.cache_line),
    };

    var counter1 = AlignedCounter{ .counter = std.atomic.Value(usize).init(0) };
    var counter2 = AlignedCounter{ .counter = std.atomic.Value(usize).init(0) };

    const addr1 = @intFromPtr(&counter1.counter);
    const addr2 = @intFromPtr(&counter2.counter);

    std.debug.print("  Counter 1 address: 0x{x}\n", .{addr1});
    std.debug.print("  Counter 2 address: 0x{x}\n", .{addr2});
    std.debug.print("  Cache line size: {} bytes\n", .{std.atomic.cache_line});

    // Verify alignment
    try testing.expect(addr1 % std.atomic.cache_line == 0);
    try testing.expect(addr2 % std.atomic.cache_line == 0);

    std.debug.print("  ✅ PASS - Counters aligned to cache line boundaries\n\n", .{});
}

// ============================================================================
// Memory Ordering Demonstration
// ============================================================================

test "memory ordering: monotonic vs seq_cst" {
    std.debug.print("=== Memory Ordering Examples ===\n", .{});

    var counter = std.atomic.Value(usize).init(0);

    // Monotonic - no synchronization, just atomic operation
    _ = counter.fetchAdd(1, .monotonic);
    std.debug.print("  .monotonic: counter={}\n", .{counter.load(.monotonic)});

    // Seq_cst - full sequential consistency
    _ = counter.fetchAdd(1, .seq_cst);
    std.debug.print("  .seq_cst: counter={}\n", .{counter.load(.seq_cst)});

    // Acquire-Release pair
    counter.store(100, .release);
    const value = counter.load(.acquire);
    std.debug.print("  .release/.acquire: value={}\n", .{value});

    try testing.expectEqual(@as(usize, 100), value);

    std.debug.print("  ✅ PASS\n\n", .{});
}
