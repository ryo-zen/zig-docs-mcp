# std.mem

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all mem features

## Quick Start

### Most Common Patterns

**Compare Slices**
```zig
const a = "hello";
const b = "hello";
if (std.mem.eql(u8, a, b)) {
    std.debug.print("Equal!\n", .{});
}
```

**Find in Slice**
```zig
const text = "Hello, World!";
if (std.mem.indexOf(u8, text, "World")) |index| {
    std.debug.print("Found at index {d}\n", .{index}); // 7
}
```

**Copy Memory**
```zig
const src = [_]u8{ 1, 2, 3, 4, 5 };
var dst: [5]u8 = undefined;
@memcpy(&dst, &src);
// dst is now [1, 2, 3, 4, 5]
```

**Split String**
```zig
var iter = std.mem.splitScalar(u8, "a,b,c", ',');
while (iter.next()) |part| {
    std.debug.print("Part: {s}\n", .{part}); // "a", "b", "c"
}
```

**Trim Whitespace**
```zig
const trimmed = std.mem.trim(u8, "  hello  ", " \t\n");
// trimmed = "hello"
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Compare slices | `eql()` | `std.mem.eql(u8, a, b)` |
| Find substring | `indexOf()` | `std.mem.indexOf(u8, haystack, needle)` |
| Find element | `indexOfScalar()` | `std.mem.indexOfScalar(u8, slice, 'x')` |
| Check prefix | `startsWith()` | `std.mem.startsWith(u8, str, "prefix")` |
| Check suffix | `endsWith()` | `std.mem.endsWith(u8, str, "suffix")` |
| Split string | `splitScalar()` | `std.mem.splitScalar(u8, str, ',')` |
| Trim ends | `trim()` | `std.mem.trim(u8, str, " \t\n")` |
| Concatenate | `concat()` | `std.mem.concat(allocator, u8, slices)` |
| Replace | `replace()` | `std.mem.replace(u8, input, old, new, output)` |
| Sort | `sort()` | `std.mem.sort(u8, items, {}, lessThan)` |

### ⚠️ Critical: Use @memcpy for Overlapping Memory

```zig
// WRONG - copyForwards/copyBackwards are deprecated
std.mem.copyForwards(u8, dest, source); // ❌ Deprecated

// CORRECT - Use @memcpy (handles overlaps correctly)
@memcpy(dest, source); // ✅ Always safe
```

---

## Overview

`std.mem` provides fundamental memory operations for working with slices, pointers, and byte sequences in Zig. It's the core toolkit for string processing, slice manipulation, searching, copying, and low-level memory operations.

**Key Characteristics:**
- **Type-generic** - Most functions work with any slice type via `comptime T: type`
- **Zero-allocation** - Many operations work in-place or with caller-provided buffers
- **Explicit endianness** - Byte order conversions are explicit and clear
- **Safety-focused** - Functions assert preconditions and avoid undefined behavior
- **Iterator-based** - Complex operations like split/tokenize use iterators
- **No hidden allocations** - Functions requiring allocation take explicit `Allocator` parameter

**When to use std.mem:**
- String searching, splitting, and manipulation
- Comparing slices for equality or ordering
- Copying, concatenating, or transforming byte sequences
- Reading/writing integers with specific endianness
- Sorting arrays with custom comparison functions
- Working with pointers and memory alignment
- Converting between types and byte representations

**Related namespaces:**
- `std.fmt` - String formatting and parsing (higher-level)
- `std.heap` - Memory allocation strategies
- `std.ArrayList` - Dynamic array type
- `std.io` - Buffered I/O operations

---

## Searching & Finding Functions

### `pub fn indexOf(comptime T: type, haystack: []const T, needle: []const T) ?usize`

Searches for the first occurrence of a subsequence within a slice. Returns the index or `null` if not found. Uses Boyer-Moore-Horspool algorithm on large inputs for efficiency.

**Example:**
```zig
const text = "The quick brown fox";
const index = std.mem.indexOf(u8, text, "quick"); // 4
const missing = std.mem.indexOf(u8, text, "slow"); // null
```

------

### `pub fn indexOfScalar(comptime T: type, slice: []const T, value: T) ?usize`

Linear search for a single element in a slice.

**Example:**
```zig
const numbers = [_]i32{ 10, 20, 30, 40 };
const index = std.mem.indexOfScalar(i32, &numbers, 30); // 2
```

------

### `pub fn lastIndexOf(comptime T: type, haystack: []const T, needle: []const T) ?usize`

Searches backwards from the end. Returns the index of the last occurrence.

**Example:**
```zig
const text = "one two one";
const index = std.mem.lastIndexOf(u8, text, "one"); // 8
```

------

### `pub fn indexOfAny(comptime T: type, slice: []const T, values: []const T) ?usize`

Finds the first occurrence of ANY value from a set.

**Example:**
```zig
const text = "hello";
const index = std.mem.indexOfAny(u8, text, "aeiou"); // 1 (found 'e')
```

------

### `pub fn indexOfNone(comptime T: type, slice: []const T, values: []const T) ?usize`

Finds the first element NOT in the given set.

**Example:**
```zig
const digits = "12345abc";
const index = std.mem.indexOfNone(u8, digits, "0123456789"); // 5 (found 'a')
```

------

### `pub fn containsAtLeast(comptime T: type, haystack: []const T, expected_count: usize, needle: []const T) bool`

Returns `true` if `needle` appears at least `expected_count` times in `haystack`.

**Example:**
```zig
const text = "banana";
const result = std.mem.containsAtLeast(u8, text, 2, "na"); // true
```

------

### `pub fn count(comptime T: type, haystack: []const T, needle: []const T) usize`

Counts non-overlapping occurrences of `needle` in `haystack`.

**Example:**
```zig
const text = "ababab";
const n = std.mem.count(u8, text, "ab"); // 3
```

------

### `pub fn countScalar(comptime T: type, list: []const T, element: T) usize`

Counts occurrences of a single element.

**Example:**
```zig
const text = "hello";
const n = std.mem.countScalar(u8, text, 'l'); // 2
```

------

## Comparison & Ordering Functions

### `pub fn eql(comptime T: type, a: []const T, b: []const T) bool`

Returns `true` if slices have the same length and all elements are equal.

**Example:**
```zig
const a = "hello";
const b = "hello";
const c = "world";

std.mem.eql(u8, a, b); // true
std.mem.eql(u8, a, c); // false
```

------

### `pub fn order(comptime T: type, lhs: []const T, rhs: []const T) math.Order`

Lexicographically compares two slices. Returns `.lt`, `.eq`, or `.gt`.

**Example:**
```zig
const result = std.mem.order(u8, "abc", "abd");
// result == .lt (abc < abd)
```

------

### `pub fn lessThan(comptime T: type, lhs: []const T, rhs: []const T) bool`

Returns `true` if `lhs` is lexicographically less than `rhs`.

**Example:**
```zig
std.mem.lessThan(u8, "abc", "xyz"); // true
```

------

### `pub fn startsWith(comptime T: type, haystack: []const T, needle: []const T) bool`

Returns `true` if `haystack` begins with `needle`.

**Example:**
```zig
const text = "Hello, World!";
std.mem.startsWith(u8, text, "Hello"); // true
std.mem.startsWith(u8, text, "World"); // false
```

------

### `pub fn endsWith(comptime T: type, haystack: []const T, needle: []const T) bool`

Returns `true` if `haystack` ends with `needle`.

**Example:**
```zig
const file = "document.txt";
std.mem.endsWith(u8, file, ".txt"); // true
```

------

## Slicing & Manipulation Functions

### `pub fn splitScalar(comptime T: type, buffer: []const T, delimiter: T) SplitIterator(T, .scalar)`

Returns an iterator over slices separated by a single delimiter. Preserves empty fields.

**Example:**
```zig
var iter = std.mem.splitScalar(u8, "a,b,,c", ',');
while (iter.next()) |part| {
    // Yields: "a", "b", "", "c"
}
```

See [std.mem.SplitIterator](std.mem.SplitIterator.md) for details.

------

### `pub fn splitSequence(comptime T: type, buffer: []const T, delimiter: []const T) SplitIterator(T, .sequence)`

Splits on a multi-character delimiter sequence.

**Example:**
```zig
var iter = std.mem.splitSequence(u8, "one::two::three", "::");
// Yields: "one", "two", "three"
```

------

### `pub fn tokenizeScalar(comptime T: type, buffer: []const T, delimiter: T) TokenIterator(T, .scalar)`

Like `splitScalar` but skips empty fields (consecutive delimiters).

**Example:**
```zig
var iter = std.mem.tokenizeScalar(u8, "a,b,,c", ',');
while (iter.next()) |token| {
    // Yields: "a", "b", "c" (empty field skipped)
}
```

See [std.mem.TokenIterator](std.mem.TokenIterator.md) for details.

------

### `pub fn trim(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`

Removes any elements in `values_to_strip` from both ends of `slice`.

**Example:**
```zig
const result = std.mem.trim(u8, "  hello  ", " \t\n");
// result = "hello"
```

------

### `pub fn trimLeft(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`

Removes elements from the beginning only.

**Example:**
```zig
const result = std.mem.trimLeft(u8, "###hello", "#");
// result = "hello"
```

------

### `pub fn trimRight(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`

Removes elements from the end only.

**Example:**
```zig
const result = std.mem.trimRight(u8, "hello...", ".");
// result = "hello"
```

------

### `pub fn span(ptr: anytype) Span(@TypeOf(ptr))`

Converts a sentinel-terminated pointer to a slice by finding the sentinel.

**Example:**
```zig
const c_string: [*:0]const u8 = "hello";
const slice = std.mem.span(c_string);
// slice = "hello" (type: []const u8)
```

------

### `pub fn sliceTo(ptr: anytype, comptime end: T) SliceTo(@TypeOf(ptr), end)`

Returns a slice up to (but not including) the first occurrence of `end`.

**Example:**
```zig
const data = "name=value";
const name = std.mem.sliceTo(data, '=');
// name = "name"
```

------

### `pub fn cut(comptime T: type, haystack: []const T, needle: []const T) ?struct { []const T, []const T }`

Splits `haystack` at the first occurrence of `needle`, returning both parts (before and after).

**Example:**
```zig
const text = "key:value";
if (std.mem.cut(u8, text, ":")) |result| {
    // result[0] = "key"
    // result[1] = "value"
}
```

------

## Copying & Joining Functions

### `pub fn concat(allocator: Allocator, comptime T: type, slices: []const []const T) ![]T`

Allocates and concatenates multiple slices into one.

**Example:**
```zig
const allocator = std.testing.allocator;
const parts = [_][]const u8{ "Hello", " ", "World" };
const result = try std.mem.concat(allocator, u8, &parts);
defer allocator.free(result);
// result = "Hello World"
```

------

### `pub fn join(allocator: Allocator, separator: []const u8, slices: []const []const u8) ![]u8`

Joins slices with a separator between them.

**Example:**
```zig
const allocator = std.testing.allocator;
const words = [_][]const u8{ "one", "two", "three" };
const result = try std.mem.join(allocator, ", ", &words);
defer allocator.free(result);
// result = "one, two, three"
```

------

### `pub fn replace(comptime T: type, input: []const T, needle: []const T, replacement: []const T, output: []T) usize`

Replaces all occurrences of `needle` with `replacement`, writing to `output`. Returns number of replacements made.

**Example:**
```zig
const input = "foo bar foo";
var output: [20]u8 = undefined;
const n = std.mem.replace(u8, input, "foo", "baz", &output);
// output[0..n] = "baz bar baz", n = 2
```

------

### `pub fn replaceScalar(comptime T: type, slice: []T, match: T, replacement: T) void`

In-place replacement of all occurrences of a single element.

**Example:**
```zig
var text = "hello".*;
std.mem.replaceScalar(u8, &text, 'l', 'L');
// text = "heLLo"
```

------

## Byte & Endianness Functions

### `pub fn readInt(comptime T: type, buffer: *const [@divExact(@typeInfo(T).int.bits, 8)]u8, endian: Endian) T`

Reads an integer from a byte array with specified endianness.

**Example:**
```zig
const bytes = [_]u8{ 0x12, 0x34, 0x56, 0x78 };
const value = std.mem.readInt(u32, &bytes, .big);
// value = 0x12345678
```

------

### `pub fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).int.bits, 8)]u8, value: T, endian: Endian) void`

Writes an integer to a byte array with specified endianness.

**Example:**
```zig
var bytes: [4]u8 = undefined;
std.mem.writeInt(u32, &bytes, 0x12345678, .little);
// bytes = [0x78, 0x56, 0x34, 0x12]
```

------

### `pub fn nativeToBig(comptime T: type, x: T) T`

Converts from host endianness to big-endian.

**Example:**
```zig
const network_order = std.mem.nativeToBig(u32, 0x12345678);
```

------

### `pub fn nativeToLittle(comptime T: type, x: T) T`

Converts from host endianness to little-endian.

------

### `pub fn bigToNative(comptime T: type, x: T) T`

Converts from big-endian to host endianness.

------

### `pub fn littleToNative(comptime T: type, x: T) T`

Converts from little-endian to host endianness.

------

### `pub fn byteSwapAllFields(comptime S: type, ptr: *S) void`

Recursively swaps byte order of all fields in a struct.

**Example:**
```zig
const Header = struct { magic: u32, version: u16, flags: u16 };
var header = Header{ .magic = 0x12345678, .version = 1, .flags = 0 };
std.mem.byteSwapAllFields(Header, &header);
// All fields now reversed
```

------

## Alignment Functions

### `pub fn isAligned(addr: usize, alignment: usize) bool`

Returns `true` if `addr` is aligned to `alignment` (must be power of 2).

**Example:**
```zig
std.mem.isAligned(0x1000, 16); // true
std.mem.isAligned(0x1001, 16); // false
```

------

### `pub fn alignForward(comptime T: type, addr: T, alignment: T) T`

Rounds an address up to the next aligned address.

**Example:**
```zig
const aligned = std.mem.alignForward(usize, 0x1001, 16);
// aligned = 0x1010
```

------

### `pub fn alignBackward(comptime T: type, addr: T, alignment: T) T`

Rounds an address down to the previous aligned address.

**Example:**
```zig
const aligned = std.mem.alignBackward(usize, 0x1015, 16);
// aligned = 0x1010
```

------

## Min/Max Functions

### `pub fn min(comptime T: type, slice: []const T) T`

Returns the smallest value in a non-empty slice.

**Example:**
```zig
const numbers = [_]i32{ 10, 5, 20, 3 };
const smallest = std.mem.min(i32, &numbers); // 3
```

------

### `pub fn max(comptime T: type, slice: []const T) T`

Returns the largest value in a non-empty slice.

**Example:**
```zig
const numbers = [_]i32{ 10, 5, 20, 3 };
const largest = std.mem.max(i32, &numbers); // 20
```

------

### `pub fn indexOfMin(comptime T: type, slice: []const T) usize`

Returns the index of the smallest value.

------

### `pub fn indexOfMax(comptime T: type, slice: []const T) usize`

Returns the index of the largest value.

------

## Type Conversion Functions

### `pub fn asBytes(ptr: anytype) AsBytesReturnType(@TypeOf(ptr))`

Given a pointer to a single item, returns a slice of its underlying bytes.

**Example:**
```zig
const value: u32 = 0x12345678;
const bytes = std.mem.asBytes(&value);
// bytes.len = 4
```

------

### `pub fn bytesAsSlice(comptime T: type, bytes: anytype) BytesAsSliceReturnType(T, @TypeOf(bytes))`

Interprets a byte slice as a slice of another type.

**Example:**
```zig
const bytes = [_]u8{ 1, 0, 2, 0, 3, 0 };
const shorts = std.mem.bytesAsSlice(u16, &bytes);
// shorts = [1, 2, 3] (assuming little-endian)
```

------

### `pub fn bytesAsValue(comptime T: type, bytes: anytype) BytesAsValueReturnType(T, @TypeOf(bytes))`

Interprets bytes as a pointer to a single value.

**Example:**
```zig
const bytes = [_]u8{ 0x78, 0x56, 0x34, 0x12 };
const value_ptr = std.mem.bytesAsValue(u32, &bytes);
// value_ptr.* = 0x12345678 (little-endian)
```

------

### `pub fn toBytes(value: anytype) [@sizeOf(@TypeOf(value))]u8`

Returns a copy of a value's bytes as an array.

**Example:**
```zig
const value: u32 = 0x12345678;
const bytes = std.mem.toBytes(value);
// bytes is [4]u8
```

------

## Sorting Functions

### `pub fn sort(comptime T: type, items: []T, context: anytype, comptime lessThan: fn (@TypeOf(context), T, T) bool) void`

Stable in-place sort. Preserves relative order of equal elements.

**Example:**
```zig
const numbers = [_]i32{ 3, 1, 4, 1, 5 };
var sorted = numbers;
std.mem.sort(i32, &sorted, {}, comptime std.sort.asc(i32));
// sorted = [1, 1, 3, 4, 5]
```

------

### `pub fn sortUnstable(comptime T: type, items: []T, context: anytype, comptime lessThan: fn (@TypeOf(context), T, T) bool) void`

Unstable in-place sort. Faster but doesn't preserve order of equal elements.

------

## Utility Functions

### `pub fn reverse(comptime T: type, items: []T) void`

In-place reversal of a slice.

**Example:**
```zig
var numbers = [_]i32{ 1, 2, 3, 4, 5 };
std.mem.reverse(i32, &numbers);
// numbers = [5, 4, 3, 2, 1]
```

------

### `pub fn rotate(comptime T: type, items: []T, amount: usize) void`

Rotates elements left by `amount` positions.

**Example:**
```zig
var items = [_]u8{ 1, 2, 3, 4 };
std.mem.rotate(u8, &items, 1);
// items = [2, 3, 4, 1]
```

------

### `pub fn swap(comptime T: type, a: *T, b: *T) void`

Exchanges the contents of two memory locations.

**Example:**
```zig
var x: i32 = 10;
var y: i32 = 20;
std.mem.swap(i32, &x, &y);
// x = 20, y = 10
```

------

### `pub fn len(value: anytype) usize`

Finds the length of a sentinel-terminated pointer.

**Example:**
```zig
const c_str: [*:0]const u8 = "hello";
const length = std.mem.len(c_str); // 5
```

------

### `pub fn zeroes(comptime T: type) T`

Returns a zero-initialized value of type `T`.

**Example:**
```zig
const Point = struct { x: i32, y: i32 };
const origin = std.mem.zeroes(Point);
// origin = Point{ .x = 0, .y = 0 }
```

------

### `pub fn zeroInit(comptime T: type, init: anytype) T`

Initializes a struct with specified fields, zeroing others.

**Example:**
```zig
const Point = struct { x: i32 = 0, y: i32 = 0, z: i32 = 0 };
const pt = std.mem.zeroInit(Point, .{ .x = 10 });
// pt = Point{ .x = 10, .y = 0, .z = 0 }
```

------

## Usage Patterns

### Pattern 1: Parsing CSV Data

```zig
const std = @import("std");

pub fn parseCsv(line: []const u8) void {
    var iter = std.mem.splitScalar(u8, line, ',');
    while (iter.next()) |field| {
        const trimmed = std.mem.trim(u8, field, " \t");
        std.debug.print("Field: '{s}'\n", .{trimmed});
    }
}

pub fn main() void {
    parseCsv("Alice, 30, Engineer");
    // Outputs:
    // Field: 'Alice'
    // Field: '30'
    // Field: 'Engineer'
}
```

------

### Pattern 2: Building Paths Safely

```zig
const std = @import("std");

pub fn buildPath(allocator: std.mem.Allocator, parts: []const []const u8) ![]u8 {
    return std.mem.join(allocator, "/", parts);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const parts = [_][]const u8{ "home", "user", "documents", "file.txt" };
    const path = try buildPath(allocator, &parts);
    defer allocator.free(path);

    std.debug.print("Path: {s}\n", .{path});
    // Path: home/user/documents/file.txt
}
```

------

### Pattern 3: Network Byte Order Conversion

```zig
const std = @import("std");

pub fn encodeHeader(magic: u32, version: u16, flags: u16) [8]u8 {
    var buffer: [8]u8 = undefined;

    // Write in network byte order (big-endian)
    std.mem.writeInt(u32, buffer[0..4], magic, .big);
    std.mem.writeInt(u16, buffer[4..6], version, .big);
    std.mem.writeInt(u16, buffer[6..8], flags, .big);

    return buffer;
}

pub fn decodeHeader(buffer: [8]u8) struct { magic: u32, version: u16, flags: u16 } {
    return .{
        .magic = std.mem.readInt(u32, buffer[0..4], .big),
        .version = std.mem.readInt(u16, buffer[4..6], .big),
        .flags = std.mem.readInt(u16, buffer[6..8], .big),
    };
}
```

------

### Pattern 4: String Prefix/Suffix Handling

```zig
const std = @import("std");

pub fn stripPrefix(str: []const u8, prefix: []const u8) []const u8 {
    if (std.mem.startsWith(u8, str, prefix)) {
        return str[prefix.len..];
    }
    return str;
}

pub fn stripSuffix(str: []const u8, suffix: []const u8) []const u8 {
    if (std.mem.endsWith(u8, str, suffix)) {
        return str[0 .. str.len - suffix.len];
    }
    return str;
}

pub fn main() void {
    const url = "https://example.com/path";
    const path = stripPrefix(url, "https://example.com");
    std.debug.print("Path: {s}\n", .{path}); // /path

    const file = "document.txt";
    const name = stripSuffix(file, ".txt");
    std.debug.print("Name: {s}\n", .{name}); // document
}
```

------

## Types and Constants

### Iterator Types

- **[std.mem.SplitIterator](std.mem.SplitIterator.md)** - Forward iteration over delimited sequences (preserves empty fields)
- **[std.mem.SplitBackwardsIterator](std.mem.SplitBackwardsIterator.md)** - Backward iteration over delimited sequences
- **[std.mem.TokenIterator](std.mem.TokenIterator.md)** - Forward iteration skipping empty fields
- **[std.mem.WindowIterator](std.mem.WindowIterator.md)** - Sliding window iteration over slices

### Core Types

- **[std.mem.Allocator](std.mem.Allocator.md)** - Standard memory allocation interface
- **[std.mem.Alignment](std.mem.Alignment.md)** - Alignment representation type
- **[std.mem.DelimiterType](std.mem.DelimiterType.md)** - Delimiter interpretation mode (scalar/any/sequence)
- **[std.mem.ValidationAllocator](std.mem.ValidationAllocator.md)** - Allocator wrapper with validation checks

### Constants

**`byte_size_in_bits: usize = 8`**

Zig assumes 8-bit bytes. This constant documents that assumption and allows searching for platform-dependent code if Zig is ever ported to non-8-bit-byte platforms.

------

## Error Sets

Most `std.mem` functions do not return errors. Functions that allocate memory return `Allocator.Error`.

---

## Debug Checklist

✅ **Use @memcpy instead of copyForwards/copyBackwards** - The old functions are deprecated

✅ **Check slice bounds** - Many functions assume slices are non-empty or properly sized

✅ **Alignment must be power of 2** - Alignment functions require power-of-2 alignment values

✅ **Endianness is explicit** - No implicit byte order conversions; always specify `.big` or `.little`

✅ **indexOf returns ?usize** - Handle the `null` case when element not found

✅ **Free allocated results** - Functions like `concat` and `join` return owned memory

✅ **Split vs Tokenize** - `split` preserves empty fields; `tokenize` skips them

✅ **Needle must not be empty** - Functions like `replace` and `count` require non-empty needle

✅ **Output buffer sized correctly** - Functions like `replace` need properly sized output buffers

✅ **Slices must not overlap** - Unless using @memcpy; functions like `replace` require non-overlapping input/output

---

## Performance Tips

1. **Use @memcpy for copying** - It's a compiler builtin, optimized to use platform-specific instructions (like SIMD).

2. **Prefer scalar functions for single elements** - `indexOfScalar` is faster than `indexOf` for single-element needles.

3. **Use Boyer-Moore for large searches** - `indexOf` automatically uses it for large inputs; no need to call `indexOfPos` manually.

4. **Pre-allocate for join/concat** - Calculate the total size first if you need to reuse the buffer:
   ```zig
   var total_size: usize = 0;
   for (slices) |s| total_size += s.len;
   const buffer = try allocator.alloc(u8, total_size);
   ```

5. **Sort is stable but slower** - Use `sortUnstable` if you don't care about preserving order of equal elements.

6. **Reuse iterators when possible** - Create one iterator and reset it rather than creating new ones in a loop.

7. **Avoid repeated searches** - Cache `indexOf` results if you'll search for the same thing multiple times.

8. **Use span for C strings once** - Convert sentinel-terminated pointers to slices early, then work with slices.

9. **Batch endianness conversions** - Convert multiple values in one pass rather than calling conversion functions repeatedly.

10. **In-place operations are zero-copy** - Functions like `reverse`, `rotate`, and `replaceScalar` work in-place with no allocation.

---

## See Also

- **std.fmt** - String formatting and parsing (higher-level text operations)
- **std.heap** - Memory allocation strategies and allocators
- **std.ArrayList** - Dynamic array with automatic growth
- **std.io** - Buffered I/O and stream operations
- **std.sort** - Additional sorting utilities and comparison helpers
- **std.unicode** - UTF-8 and UTF-16 handling
