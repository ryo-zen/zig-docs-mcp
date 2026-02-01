# Zig Documentation Examples - Test Suite

This directory contains runnable test examples for the Zig std.Io documentation.

## Test Files

### 1. test_networking_basics.zig
Tests examples from network-related documentation:
- `std.Io.net.ShutdownHow` - Socket shutdown directions
- `std.Io.net.ReceiveFlags` - Socket receive flags
- `std.Io.net.SendFlags` - Socket send flags
- `std.Io.net` - Networking namespace

**Tests:** 4 passing

### 2. test_limit.zig
Tests examples from `std.Io.Limit` documentation:
- Basic initialization (limited, unlimited, nothing)
- Buffer slicing operations
- Subtract operations with overflow detection
- Min/max comparisons
- Const slicing
- Vector byte counting

**Tests:** 10 passing

### 3. test_sync_primitives.zig
Tests examples from synchronization primitive documentation:
- `std.Io.Event` - Event synchronization
- `std.Io.Mutex` - Mutual exclusion locks
- `std.Io.CancelProtection` - Cancellation protection states

**Tests:** 10 passing

### 4. test_queue_and_select.zig
Tests examples from queue and select documentation:
- `std.Io.TypeErasedQueue` - Byte-level queue operations
- `std.Io.SelectUnion` - Union type generation
- `std.Io.Select` - Racing multiple operations

**Tests:** 5 passing

### 5. test_kqueue.zig
Tests examples from `std.Io.Kqueue` documentation:
- Platform-specific initialization (macOS/BSD only)
- InitOptions structure

**Tests:** 1 passing, 1 skipped (platform-specific)

## Running Tests

### Run All Tests
```bash
zig test test_all.zig
```

### Run Individual Test Files
```bash
zig test test_networking_basics.zig
zig test test_limit.zig
zig test test_sync_primitives.zig
zig test test_queue_and_select.zig
zig test test_kqueue.zig
```

## Test Results

**Total Tests:** 32
- **Passing:** 31
- **Skipped:** 1 (platform-specific)
- **Failed:** 0

All code examples from the documentation compile and run successfully on Zig 0.16.

## Notes

- **Platform-Specific Tests:** Kqueue tests are only available on macOS and BSD systems. On Linux, they are skipped with `error.SkipZigTest`.
- **Io Backend:** Tests use `std.Io.Threaded` backend for cross-platform compatibility.
- **Minimal Examples:** These are simplified versions focusing on API correctness. Full real-world examples would include more error handling and business logic.

## Coverage

The test suite validates:
- ✅ Type initialization
- ✅ Basic operations (lock, unlock, put, get, etc.)
- ✅ Error handling patterns
- ✅ Enum and flag values
- ✅ Type safety and field access
- ✅ Platform-specific conditional compilation

## Adding New Tests

When adding new documentation examples:
1. Create a new test file or add to existing file
2. Follow the pattern: `test "Component - feature" { ... }`
3. Add import to `test_all.zig`
4. Run `zig test test_all.zig` to verify
5. Update this README with test counts
