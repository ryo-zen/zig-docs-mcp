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
- **Allocator:** DebugAllocator with leak detection
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

---

## Stdlib Docs Audit Update

## Date: 2026-05-25

### Audit Summary

The stdlib documentation audit now checks existing markdown correctness, `std.Io` public declaration coverage, and top-level `std` Types/Namespaces/Values from the locked local `std.zig` source.

**Completed:**
- Added `npm run audit:stdlib-docs` coverage for expected `std.Io` public declarations.
- Added source-driven root `std` coverage so missing top-level Types, Namespaces, and Values are reported from local `std.zig`.
- Fixed stale Zig 0.16 symbol paths for JSON, math, BufMap, BufSet, and Io docs.
- Removed stale docs for removed APIs such as `std.process.ProtectMemoryOptions`, `std.Io.Poller`, `std.Io.PollFiles`, and `std.Io.SelectUnion`.
- Added missing markdown pages for:
  - `std.Io.AnyFuture`
  - `std.Io.Batch`
  - `std.Io.Condition`
  - `std.Io.Dispatch`
  - `std.Io.Operation`
  - `std.Io.RwLock`
  - `std.Io.Semaphore`
  - `std.Io.failingNetSend`
- Added first root `std` Type pages for the hash map and static string map family:
  - `std.AutoHashMap`
  - `std.AutoHashMapUnmanaged`
  - `std.HashMap`
  - `std.HashMapUnmanaged`
  - `std.StringHashMap`
  - `std.StringHashMapUnmanaged`
  - `std.StaticStringMap`
  - `std.StaticStringMapWithEql`
- Updated resolver support for import-member aliases, nested declarations, enum values, union fields, qualified public functions, and field references.

**Latest verification:**
- `npm run audit:stdlib-docs -- --path zig_docs_std/Types/Io --fail-on-issues`
  - 49 checked
  - 49 OK
  - 0 warnings
  - 0 errors
- `npm run audit:stdlib-docs -- --path zig_docs_std/Types --max 80`
  - 96 checked
  - 69 OK
  - 0 warnings
  - 26 errors for missing root Type docs
  - 1 skipped non-symbol file
- `npm run audit:stdlib-docs -- --path zig_docs_std/Namespaces --max 100`
  - 361 checked
  - 324 OK
  - 0 warnings
  - 35 errors for missing root Namespace/Value docs
  - 2 skipped non-symbol files
- `npm run audit:stdlib-docs -- --max 20`
  - 457 checked
  - 393 OK
  - 0 warnings
  - 61 errors for missing root docs
  - 3 skipped non-symbol files
- `npm test`
  - 53 tests passed

### Reusable Coverage Workflow

Use this same workflow for other `Types` and `Namespaces`:

1. Pick a documentation area, for example `std.Io`, `std.fs`, `std.process`, or a `Types/*` group.
2. Read the locked local stdlib source under `/path/to/zig-0.16.0/lib/std`.
3. List the public declarations that should have standalone markdown pages.
4. Compare those declarations to existing markdown H1 symbols and filenames.
5. Add a `CoverageRule` in `src/audit-stdlib-docs.ts` for explicit declaration lists, or use `ROOT_COVERAGE_RULES` for source-driven root surfaces.
6. For explicit rules include:
   - `namespace`
   - `docRoot`
   - `expectedDir`
   - `symbols`
7. Run a targeted audit with `--fail-on-issues` to expose missing docs.
8. Add missing markdown pages from the local stdlib source, keeping the H1 exactly equal to the public symbol.
9. Include source-derived fields, enum values, function signatures, behavior notes, and see-also links.
10. Run the targeted audit again until it has 0 warnings and 0 errors.
11. Run the full audit and test suite:
    - `npm run audit:stdlib-docs`
    - `npm test`

This makes missing docs a repeatable audit failure instead of a manual checklist item.
