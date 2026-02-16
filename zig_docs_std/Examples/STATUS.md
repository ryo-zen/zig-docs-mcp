# Test Status for Namespace Documentation

## Date: 2026-02-16

### Test Summary

| Namespace | Test File | Tests | Passed | Failed | Status |
|-----------|-----------|-------|--------|--------|--------|
| `std.array_list` | `array_list_namespace.tests.zig` | 23 | 23 | 0 | ✅ All Pass |
| `std.hash_map` | `hash_map_namespace.tests.zig` | 23 | 23 | 0 | ✅ All Pass |

**Total:** 46 tests, 46 passed, 0 failed

---

## std.array_list Tests (23/23 passing)

### Quick Start Patterns (3 tests)
- ✅ Basic Dynamic Array
- ✅ Pre-allocated Capacity
- ✅ String Building

### Core Functions (10 tests)
- ✅ append
- ✅ appendSlice
- ✅ insert
- ✅ orderedRemove
- ✅ swapRemove
- ✅ pop
- ✅ ensureTotalCapacity
- ✅ toOwnedSlice
- ✅ clearRetainingCapacity
- ✅ clearAndFree

### Type Variants (3 tests)
- ✅ Aligned with custom alignment
- ✅ AlignedManaged
- ✅ Managed

### Usage Patterns (3 tests)
- ✅ String Building
- ✅ Pre-allocated Buffer
- ✅ Filtering with Managed Variant

### Performance Tips (4 tests)
- ✅ Pre-allocate for loops
- ✅ swapRemove vs orderedRemove
- ✅ clearRetainingCapacity for reuse
- ✅ appendSlice vs loop append

---

## std.hash_map Tests (23/23 passing)

### Quick Start Patterns (4 tests)
- ✅ String Keys
- ✅ Integer/Enum Keys
- ✅ Counting/Frequency Map
- ✅ Iterating Over Entries

### Core Types (4 tests)
- ✅ AutoHashMap
- ✅ AutoHashMapUnmanaged
- ✅ StringHashMap
- ✅ StringHashMapUnmanaged

### Utility Functions (2 tests)
- ✅ hashString
- ✅ eqlString

### Common Operations (5 tests)
- ✅ put and get
- ✅ getOrPut
- ✅ remove
- ✅ contains
- ✅ clearAndFree

### Usage Patterns (4 tests)
- ✅ Word Frequency Counter
- ✅ Memoization Cache
- ✅ Configuration Map with Pre-allocation
- ✅ Unmanaged Map for Explicit Control

### Performance Tips (4 tests)
- ✅ Pre-allocate capacity
- ✅ Use getPtr to avoid double lookup
- ✅ putAssumeCapacity after pre-allocation
- ✅ clearRetainingCapacity for reuse

---

## Issues Found and Fixed

### Zig 0.16 API Changes

1. **ArrayList.pop() return type**
   - Returns optional `?T` in 0.16 (was `T` in earlier versions)
   - Fixed: Use `{?}` format specifier and `.?` to unwrap

2. **ArrayList.writer() removed**
   - No longer available in 0.16
   - Fixed: Use `appendSlice()` directly instead

3. **Alignment parameter type**
   - Must use `mem.Alignment` enum, not raw integers
   - Fixed: `.@"16"` instead of `16`

4. **Modulo operator with signed integers**
   - Must use `@rem()` builtin instead of `%` operator
   - Fixed: `@rem(num, 2)` instead of `num % 2`

5. **StringHashMap key lifetime**
   - Keys must have stable memory addresses
   - Fixed: Use integer keys for performance test instead of stack-allocated strings

---

## Test Environment

- **Zig Version:** 0.16.0-dev.2193+fc517bd01
- **Platform:** Linux x86_64
- **Allocator:** GeneralPurposeAllocator with leak detection
- **Command:** `zig test <filename>.tests.zig`

---

## Documentation Quality Checklist

- ✅ Created comprehensive markdown for `std.array_list`
- ✅ Created comprehensive markdown for `std.hash_map`
- ✅ Written test files covering all examples
- ✅ Run tests to validate all examples work
- ✅ Fixed API changes for Zig 0.16
- ✅ Verified all tests pass
- ✅ Updated STATUS.md with results
- ✅ Updated namespace_tracking.md (both marked as ✅ Done)

---

## Next Steps

1. **Tier 2 Priorities:**
   - `sort` - Sorting algorithms
   - `ascii` - ASCII character utilities
   - `os` - OS-level interfaces
   - `time` - Timers and timestamps
   - `http` - HTTP client/server

2. **Consider adding:**
   - Example programs demonstrating combined usage
   - Benchmark comparisons for performance tips
   - Common pitfalls section based on test failures
