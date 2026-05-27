# std.Io.Writer

📚 **Runnable examples:** `zig_docs_std/Examples/test_writer_comprehensive.zig`, `zig_docs_std/Examples/test_writer_print_examples.zig`, `zig_docs_std/Examples/test_writer_binary.zig`
📘 **Reliability playbook:** [I/O Reliability and Backpressure](../../../../zig_docs/io_reliability_backpressure.md)

## Quick Start

### Most Common Patterns

**Fixed Buffer (Stack Allocation)**
```zig
var buffer: [1024]u8 = undefined;
var writer = std.Io.Writer.fixed(&buffer);
try writer.print("Value: {d}\n", .{42});
try writer.flush();
const written = writer.buffered();
```

**Dynamic Growth (ArrayList)**
```zig
var aw = std.Io.Writer.Allocating.init(allocator);
defer aw.deinit();
try aw.writer.print("Hello {s}!", .{"World"});
const result = aw.written();  // []const u8
```

**Binary Data (Serialization)**
```zig
try writer.writeInt(u32, value, .little);  // Little-endian u32
try writer.writeInt(u64, timestamp, .big); // Big-endian u64
try writer.writeAll(bytes);                 // Raw bytes
```

**File Output**
```zig
const file = try dir.createFile(io, "output.txt", .{});
defer file.close(io);
var buffer: [4096]u8 = undefined;
var writer = file.writer(&buffer);
try writer.print("Data: {}\n", .{data});
try writer.flush();
```

### Format Specifiers
- `{s}` - String | `{d}` - Decimal | `{x}` - Hex lowercase
- `{X}` - Hex uppercase | `{b}` - Binary | `{}` - Default formatting
- `{d:0>8}` - Padded to 8 digits with leading zeros

### ⚠️ Critical: Always Flush!
```zig
try writer.writeAll("data");
try writer.flush();  // ← REQUIRED! Data may not be written until flush
```

---

## Overview

`std.Io.Writer` is Zig's buffered output interface introduced in version 0.15-0.16 as part of a major I/O overhaul. Unlike the old generic `std.io.Writer(T)`, the new `Writer` is a concrete, non-generic type that uses a buffer-over-vtable design for better performance and explicit resource management.

**Key Characteristics:**
- **Non-generic**: Single concrete type instead of generic `Writer(T)`
- **Buffered by default**: Buffer sits in the interface, not the implementation
- **Explicit flushing**: You must call `flush()` to ensure data is written
- **Zero-cost when buffered**: Operations on buffered data don't call vtable functions
- **Flexible backends**: Works with any backend implementing the VTable interface

**When to use Writer:**
- Writing formatted output to files, network sockets, or memory buffers
- Building protocol encoders or serializers
- Any scenario requiring buffered output with explicit control

**Common Gotcha - ArrayList Writers:**
- `Writer.fromArrayList(&list)` takes ownership and creates a **fixed** buffer (doesn't grow!)
- `Writer.Allocating.fromArrayList(allocator, &list)` creates a **dynamic** buffer (grows automatically)
- For building strings, use `Writer.Allocating` or the simpler `std.fmt.allocPrint()`

## Critical Concept: Explicit Buffering

⚠️ **IMPORTANT**: Unlike older Zig I/O or stdio in other languages, `Writer` buffers data by default and **requires explicit flushing**. Data written to a `Writer` may not be sent to the underlying resource until you call `flush()` or the buffer fills up.

```zig
var writer = std.Io.Writer.fixed(&buffer);
try writer.writeAll("Hello");  // Buffered - not necessarily written yet!
try writer.flush();             // NOW it's guaranteed to be written
```

## Basic Usage Examples

### Example 1: Writing to a Fixed Buffer

```zig
const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    // Write some data
    try writer.writeAll("Hello, ");
    try writer.print("World! Answer = {}\n", .{42});

    // Flush to ensure all data is written
    try writer.flush();

    // Get the buffered content
    const written = writer.buffered();
    std.debug.print("{s}", .{written});
}
```

### Example 2: Writing to a File with Io.Threaded

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    // Create an I/O backend (Threaded, Evented, etc.)
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Open a file
    const dir = std.Io.Dir.cwd();
    const file = try dir.createFile(io, "output.txt", .{});
    defer file.close(io);

    // Get a writer and use it
    var buffer: [4096]u8 = undefined;
    var writer = file.writer(&buffer);

    try writer.print("Line 1: {}\n", .{100});
    try writer.print("Line 2: {s}\n", .{"Hello"});
    try writer.flush();  // Ensure data is written to file
}
```

### Example 3: Writing to an ArrayList (Dynamic Growth)

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    var list: std.ArrayList(u8) = .{};

    // Use Writer.Allocating for dynamic growth
    var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);

    try allocating_writer.writer.print("Formatted: {d:0>4}\n", .{42});
    try allocating_writer.writer.writeAll("More data\n");
    try allocating_writer.writer.flush();

    // Convert back to ArrayList when done
    var result = allocating_writer.writer.toArrayList();
    defer result.deinit(allocator);

    std.debug.print("ArrayList contents:\n{s}", .{result.items});
}
```

**Important Note:** Use `Writer.Allocating.fromArrayList()` for dynamic growth, NOT `Writer.fromArrayList()` which takes ownership and uses it as a fixed buffer.

## Fields

`vtable: *const VTable`

Pointer to the virtual function table that defines the actual write implementation. The VTable contains function pointers for `drain`, `rebase`, and `sendFile` operations.

------

`buffer: []u8`

The buffer where data is accumulated before being flushed to the underlying resource. If this has length zero, the writer is unbuffered, and `flush()` is a no-op.

------

`end: usize = 0`

Index into `buffer` marking the boundary between buffered data and unused space. Everything before `end` contains buffered bytes; everything after is undefined.

## Nested Types

- **Allocating**: Writer that dynamically grows its buffer using an allocator
- **ByteSizeUnits**: Enum for formatting byte sizes (binary, decimal, raw)
- **Discarding**: Writer that discards all data (like `/dev/null`)
- **Hashed**: Writer that computes a hash of all written data
- **Hashing**: Generic hashed writer type
- **VTable**: Virtual function table defining the writer's actual behavior

## Core Writing Functions

These are the primary functions you'll use for writing data.

### `pub fn write(w: *Writer, bytes: []const u8) Error!usize`

Writes a slice of bytes, returning the number of bytes written. May write fewer bytes than requested (short write). For guaranteed complete writes, use `writeAll()` instead.

**Example:**
```zig
const bytes_written = try writer.write("Hello");
// bytes_written may be less than 5
```

------

### `pub fn writeAll(w: *Writer, bytes: []const u8) Error!void`

Writes all bytes from the slice, calling `drain()` as many times as necessary. Guaranteed to either write all bytes or return an error.

**Example:**
```zig
try writer.writeAll("This entire string will be written");
```

------

### `pub fn writeByte(w: *Writer, byte: u8) Error!void`

Writes a single byte, calling `drain()` as many times as necessary.

**Example:**
```zig
try writer.writeByte('\n');
```

------

### `pub fn print(w: *Writer, comptime fmt: []const u8, args: anytype) Error!void`

Renders a format string with arguments and writes the result. This is similar to `std.fmt.format()` but writes directly to the writer. If the writer returns an error, formatting stops and the error is returned.

**Format specifiers:**
- `{}` - Default formatting
- `{d}` - Decimal number
- `{x}` - Lowercase hexadecimal
- `{X}` - Uppercase hexadecimal
- `{s}` - String
- `{any}` - Debug formatting
- `{d:0>4}` - Decimal with padding (see std.fmt.Options)

**Example:**
```zig
try writer.print("User {s} has {} points\n", .{"Alice", 1337});
try writer.print("Hex: 0x{x:0>8}\n", .{0xDEADBEEF});
```

## Buffer Management Functions

### `pub fn flush(w: *Writer) Error!void`

Drains all remaining buffered data by repeatedly calling `VTable.drain` until `end` is zero. **Always call this** before you're done with the writer to ensure all data is written.

**Example:**
```zig
try writer.writeAll("Important data");
try writer.flush();  // Ensure it's actually written
```

------

### `pub fn buffered(w: *const Writer) []u8`

Returns a slice of the buffer contents that haven't been drained yet. Useful for inspecting what's currently buffered.

**Example:**
```zig
try writer.writeAll("Hello");
const buf = writer.buffered();
std.debug.print("Buffered: {s}\n", .{buf});
```

------

### `pub fn advance(w: *Writer, n: usize) void`

After calling `writableSliceGreedy()`, this function tracks how many bytes were written to the slice. Updates the internal `end` index.

------

### `pub fn ensureUnusedCapacity(w: *Writer, n: usize) Error!void`

Ensures that at least `n` bytes of unused buffer capacity are available, calling `rebase()` or `flush()` if necessary.

------

### `pub fn unusedCapacityLen(w: *const Writer) usize`

Returns the number of bytes available in the buffer before it needs to be flushed.

------

### `pub fn unusedCapacitySlice(w: *const Writer) []u8`

Returns a slice of the unused portion of the buffer.

## Writable Slice Functions

These functions provide direct access to the buffer for manual writing.

### `pub fn writableSlice(w: *Writer, len: usize) Error![]u8`

Returns a writable slice of exactly `len` bytes from the buffer. Asserts that the buffer has total capacity for `len`. After writing to this slice, call `advance(len)`.

------

### `pub fn writableSliceGreedy(w: *Writer, minimum_len: usize) Error![]u8`

Returns the largest writable slice available, but at least `minimum_len` bytes. Useful when you want to write as much as possible in one go.

**Example:**
```zig
var slice = try writer.writableSliceGreedy(100);
// Fill slice with data...
const bytes_written = fillData(slice);
writer.advance(bytes_written);
```

------

### `pub fn writableArray(w: *Writer, comptime len: usize) Error!*[len]u8`

Returns a pointer to a writable array of exactly `len` bytes.

## Formatted Output Functions

### `pub fn printInt(w: *Writer, value: anytype, base: u8, case: std.fmt.Case, options: std.fmt.Options) Error!void`

Prints an integer value in the specified base (2-36) with formatting options.

**Example:**
```zig
try writer.printInt(255, 16, .lower, .{});  // "ff"
try writer.printInt(255, 16, .upper, .{});  // "FF"
try writer.printInt(42, 2, .lower, .{});    // "101010"
```

------

### `pub fn printFloat(w: *Writer, value: anytype, options: std.fmt.Number) Error!void`

Prints a floating-point value with specified formatting. Uses decimal or scientific notation.

------

### `pub fn printHex(w: *Writer, bytes: []const u8, case: std.fmt.Case) Error!void`

Prints bytes as hexadecimal string.

**Example:**
```zig
try writer.printHex(&[_]u8{0xDE, 0xAD, 0xBE, 0xEF}, .lower);
// Output: "deadbeef"
```

------

### `pub fn printByteSize(w: *Writer, value: u64, comptime units: ByteSizeUnits, options: std.fmt.Options) Error!void`

Formats a byte size in human-readable form (KB, MB, GB, etc.). The `precision` option is ignored when `value` is less than 1KB.

**Example:**
```zig
try writer.printByteSize(1536, .binary, .{});  // "1.5 KiB"
try writer.printByteSize(1536, .decimal, .{}); // "1.5 KB"
```

------

### `pub fn printDuration(w: *Writer, nanoseconds: anytype, options: std.fmt.Options) Error!void`

Writes duration according to its signed magnitude in format: `[#y][#w][#d][#h][#m]#[.###][n|u|m]s`

**Example:**
```zig
try writer.printDuration(1_500_000_000, .{}); // "1.5s"
try writer.printDuration(90_000_000_000, .{}); // "1m30s"
```

## Binary Data Writing Functions

### `pub inline fn writeInt(w: *Writer, comptime T: type, value: T, endian: std.builtin.Endian) Error!void`

Writes an integer in the specified byte order. Asserts that `buffer` has capacity of at least `@sizeOf(T)` bytes.

**Example:**
```zig
try writer.writeInt(u32, 0x12345678, .big);    // Writes as big-endian
try writer.writeInt(u16, 1000, .little);       // Writes as little-endian
```

------

### `pub inline fn writeStruct(w: *Writer, value: anytype, endian: std.builtin.Endian) Error!void`

Writes a struct's fields in the specified byte order. Inline to avoid dead code when endianness matches host.

------

### `pub fn writeLeb128(w: *Writer, value: anytype) Error!void`

Writes a single integer as unsigned LEB128 (Little Endian Base 128) encoding.

------

### `pub fn writeSleb128(w: *Writer, value: anytype) Error!void`

Writes a single signed integer as signed LEB128 encoding.

------

### `pub fn writeUleb128(w: *Writer, value: anytype) Error!void`

Writes a single unsigned integer as ULEB128 encoding.

## Advanced Writing Functions

### `pub fn writeSplat(w: *Writer, data: []const []const u8, splat: usize) Error!usize`

Writes multiple slices repeatedly. If the total bytes fit in `unusedCapacitySlice()`, this is guaranteed to not fail, not call into VTable, and return the full number of bytes.

------

### `pub fn writeSplatAll(w: *Writer, data: [][]const u8, splat: usize) Error!void`

Like `writeSplat` but writes all data. The `data` parameter is mutable because partial writes may need to mutate fields, but it's restored before returning.

------

### `pub fn writeVec(w: *Writer, data: []const []const u8) Error!usize`

Writes multiple slices in sequence (vectorized write). If total bytes fit in buffer, guaranteed to succeed without vtable calls.

------

### `pub fn writeVecAll(w: *Writer, data: [][]const u8) Error!void`

Like `writeVec` but ensures all data is written. Mutable `data` for handling partial writes.

## Byte Repetition Functions

### `pub fn splatByte(w: *Writer, byte: u8, n: usize) Error!usize`

Writes the same byte `n` times, allowing short writes.

------

### `pub fn splatByteAll(w: *Writer, byte: u8, n: usize) Error!void`

Writes the same byte `n` times, performing as many writes as necessary.

**Example:**
```zig
try writer.splatByteAll('-', 80);  // Print 80 dashes
```

------

### `pub fn splatBytes(w: *Writer, bytes: []const u8, n: usize) Error!usize`

Writes the same slice `n` times, allowing short writes.

------

### `pub fn splatBytesAll(w: *Writer, bytes: []const u8, splat: usize) Error!void`

Writes the same slice `n` times, performing as many writes as necessary.

## File Transfer Functions

### `pub fn sendFile(w: *Writer, file_reader: *File.Reader, limit: Limit) FileError!usize`

Transfers data from a file reader. Unlike `writeSplat` and `writeVec`, this calls into VTable even if there's enough buffer capacity, allowing for optimized kernel-level transfers (e.g., `sendfile()` syscall).

------

### `pub fn sendFileAll(w: *Writer, file_reader: *File.Reader, limit: Limit) FileAllError!usize`

Like `sendFile` but ensures all bytes up to `limit` are transferred. Returns number of bytes logically written, excluding bytes already buffered.

## Specialized Writer Constructors

### `pub fn fixed(buffer: []u8) Writer`

Creates a writer that writes to a fixed buffer and returns `error.WriteFailed` when the buffer is full.

**Example:**
```zig
var buf: [1024]u8 = undefined;
var writer = std.Io.Writer.fixed(&buf);
```

------

### `pub fn fromArrayList(array_list: *ArrayList(u8)) Writer`

⚠️ **WARNING**: This function takes ownership of the ArrayList's memory and uses it as a **fixed-size buffer**. It does NOT automatically grow!

The ArrayList is emptied (`array_list.* = .empty`) and its buffer becomes the writer's fixed buffer. When the buffer fills, you'll get `error.WriteFailed`.

**For dynamic growth**, use `Writer.Allocating.fromArrayList()` instead.

**Example (fixed buffer):**
```zig
var list: std.ArrayList(u8) = .{};
try list.ensureTotalCapacity(allocator, 1024);  // Pre-allocate
var writer = std.Io.Writer.fromArrayList(&list);  // list is now empty
// Can only write up to 1024 bytes
try writer.writeAll("data");
```

------

### `pub fn Allocating.fromArrayList(allocator: Allocator, array_list: *ArrayList(u8)) Writer.Allocating`

Creates a writer that dynamically grows the ArrayList as needed. This is what you typically want for building strings dynamically.

**Example (dynamic growth):**
```zig
var list: std.ArrayList(u8) = .{};
var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);

// Automatically grows as needed
try allocating_writer.writer.print("Line {}\n", .{1});
try allocating_writer.writer.writeAll("More data\n");
try allocating_writer.writer.flush();

// Get the result back as ArrayList
var result = allocating_writer.writer.toArrayList();
defer result.deinit(allocator);
```

------

### `pub fn hashed(w: *Writer, hasher: anytype, buffer: []u8) Hashed(@TypeOf(hasher))`

Wraps a writer to compute a hash of all data written.

## Utility Functions

### `pub fn undo(w: *Writer, n: usize) void`

Moves the `end` index backward by `n` bytes, effectively "unwriting" the last `n` bytes from the buffer.

------

### `pub fn toArrayList(w: *Writer) ArrayList(u8)`

Converts the writer back to an ArrayList, transferring ownership of the buffer. This is used after writing to a `Writer.Allocating` to get the final result.

The writer's buffer is transferred to the ArrayList and the writer is left with an empty buffer. Only valid if the writer was created with `fromArrayList()` or `Allocating.fromArrayList()`.

## Error Sets

### `Error`

General write errors that may occur during write operations.

------

### `FileError`

Errors specific to file operations like `sendFile`.

------

### `FileAllError`

Errors for guaranteed-complete file transfers.

------

### `FileReadingError`

Errors specific to file reading during transfer operations.

## Debug Checklist

If your code doesn't compile, check:

1. ✅ Did you pass `io` to file operations?
2. ✅ Are you using the right Writer type?
   - `std.Io.Writer` - Standalone writer
   - `File.Writer` - File-specific writer (different API!)
3. ✅ Did you use the correct method names?
   - `writeStreamingAll()` not `writeStreaming()`
   - `readStreaming()` not `readAll()`
4. ✅ Did you initialize ArrayList correctly? (`var list: std.ArrayList(u8) = .{}`)
5. ✅ Did you use `Allocating.fromArrayList()` for dynamic growth?
6. ✅ Did you call `flush()` before reading buffered data?

## Performance Tips

1. **Size your buffer appropriately**: Larger buffers reduce syscalls but use more memory
2. **Flush strategically**: Only flush when necessary (end of logical unit, before reads)
3. **Use `writeAll` over `write`**: Unless you specifically want to handle short writes
4. **Batch small writes**: Multiple `print()` calls are cheaper than multiple flushes
5. **Consider `writableSliceGreedy`**: For bulk data, directly writing to buffer is fastest

## See Also

- `std.Io.Reader` - Companion type for buffered reading
- `std.Io.Threaded` - Thread-based I/O backend
- `std.Io.Evented` - Event-based I/O backend (async)
- `std.Io.File` - File operations with the new I/O interface
- `std.fmt` - Formatting functions used by `print()`
