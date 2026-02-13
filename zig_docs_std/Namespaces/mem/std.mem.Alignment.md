# std.mem.Alignment

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.Alignment.tests.zig)**

## Overview

`std.mem.Alignment` represents memory alignment requirements as a power of 2. Instead of storing the alignment value directly (like 8 or 16), it stores the exponent (3 for 8 bytes, 4 for 16 bytes). This compact representation is used throughout Zig's memory allocation and pointer manipulation APIs.

Memory alignment is critical for:
- **Performance**: Aligned memory accesses are faster on most architectures
- **Correctness**: Some CPU instructions require aligned data
- **ABI Compliance**: Struct layouts must respect alignment requirements

## Fields

`value: u29`

The alignment stored as a power of 2. Valid range is 0 to 29, representing alignments from 2^0 (1 byte) to 2^29 (512 MB).

**Common values**:
- `0` → 1-byte alignment (2^0)
- `1` → 2-byte alignment (2^1)
- `2` → 4-byte alignment (2^2)
- `3` → 8-byte alignment (2^3)
- `4` → 16-byte alignment (2^4)
- `5` → 32-byte alignment (2^5)
- `6` → 64-byte alignment (2^6)

## Predefined Constants

Alignment provides named constants for common alignment values:

- `@"1"` = 0 (1-byte aligned)
- `@"2"` = 1 (2-byte aligned)
- `@"4"` = 2 (4-byte aligned)
- `@"8"` = 3 (8-byte aligned)
- `@"16"` = 4 (16-byte aligned)
- `@"32"` = 5 (32-byte aligned)
- `@"64"` = 6 (64-byte aligned)

**Note**: The `@"..."` syntax is required because these are numeric identifiers.

## Functions

### Conversion Functions

`pub fn toByteUnits(a: Alignment) usize`

Converts the alignment to its actual byte value. Returns 2^value.

**Example**: `Alignment{ .value = 3 }.toByteUnits()` returns `8` (2^3).

**Use when**: You need the numeric alignment value for calculations or comparisons.

------

`pub fn fromByteUnits(n: usize) Alignment`

Creates an Alignment from a byte value. The input must be a power of 2.

**Example**: `Alignment.fromByteUnits(16)` returns `Alignment{ .value = 4 }`.

**Panics**: If `n` is not a power of 2 or is zero.

------

`pub inline fn of(comptime T: type) Alignment`

Returns the alignment requirement for type `T`. This is a compile-time function.

**Example**: `Alignment.of(u64)` returns `Alignment{ .value = 3 }` (8-byte aligned on most platforms).

**Use when**: You need to query the natural alignment of a type.

### Address Alignment Functions

`pub fn forward(a: Alignment, address: usize) usize`

Rounds an address up to the next aligned boundary. If the address is already aligned, returns it unchanged.

**Example**: `Alignment{ .value = 2 }.forward(5)` returns `8` (next 4-byte boundary).

**Use when**: Allocating memory or advancing pointers to meet alignment requirements.

------

`pub fn backward(a: Alignment, address: usize) usize`

Rounds an address down to the previous aligned boundary. If the address is already aligned, returns it unchanged.

**Example**: `Alignment{ .value = 2 }.backward(7)` returns `4` (previous 4-byte boundary).

**Use when**: Finding the aligned start of a memory region.

------

`pub fn check(a: Alignment, address: usize) bool`

Tests whether an address meets the alignment requirement.

**Example**: `Alignment{ .value = 2 }.check(8)` returns `true` (8 is 4-byte aligned).

**Use when**: Validating pointer alignment before unsafe operations.

### Comparison Functions

`pub fn compare(lhs: Alignment, op: std.math.CompareOperator, rhs: Alignment) bool`

Compares two alignments using the specified operator (`.lt`, `.lte`, `.eq`, `.gte`, `.gt`).

**Example**: `Alignment{ .value = 3 }.compare(.gt, Alignment{ .value = 2 })` returns `true`.

------

`pub fn order(lhs: Alignment, rhs: Alignment) std.math.Order`

Returns the ordering relationship between two alignments (`.lt`, `.eq`, or `.gt`).

**Example**: `Alignment{ .value = 2 }.order(Alignment{ .value = 4 })` returns `.lt`.

------

`pub fn max(lhs: Alignment, rhs: Alignment) Alignment`

Returns the larger (stricter) alignment requirement.

**Example**: `Alignment.max(.@"4", .@"8")` returns `.@"8"`.

**Use when**: Combining alignment requirements from multiple sources.

------

`pub fn min(lhs: Alignment, rhs: Alignment) Alignment`

Returns the smaller (weaker) alignment requirement.

**Example**: `Alignment.min(.@"4", .@"8")` returns `.@"4"`.

## Usage Example

```zig
const std = @import("std");
const Alignment = std.mem.Alignment;

// Get alignment for a type
const u64_align = Alignment.of(u64); // typically 3 (8 bytes)
const bytes = u64_align.toByteUnits(); // 8

// Check if address is aligned
const addr: usize = 0x1000;
const is_aligned = Alignment.@"16".check(addr); // true if addr is 16-byte aligned

// Round address to alignment
const next = Alignment.@"8".forward(0x1005); // 0x1008
const prev = Alignment.@"8".backward(0x1005); // 0x1000

// Compare alignments
const stricter = Alignment.max(.@"4", .@"8"); // .@"8"
```
