# std.Io.Reader

📚 **[See Comprehensive Examples & Tests](../../Examples/std.Io.reader.tests.md)** - Complete runnable code demonstrating all Reader features

## Quick Start

### Most Common Patterns

**Reading from a File**
```zig
const file = try dir.openFile(io, "input.txt", .{});
defer file.close(io);
var buffer: [4096]u8 = undefined;
var reader = file.reader(&buffer);
const line = try reader.takeDelimiterInclusive('\n');
```

**Reading Fixed Buffer (Memory)**
```zig
const data = "Hello, World!";
var reader = std.Io.Reader.fixed(data);
const byte = try reader.takeByte();
const word = try reader.peek(5);
```

**Reading Binary Data**
```zig
const value = try reader.takeInt(u32, .little);  // Little-endian u32
const timestamp = try reader.takeInt(u64, .big); // Big-endian u64
const bytes = try reader.takeArray(16);          // Fixed-size array
```

**Reading Until Delimiter**
```zig
// Read up to newline (exclusive)
const line = try reader.takeDelimiterExclusive('\n');

// Read up to newline (inclusive)
const line_with_newline = try reader.takeDelimiterInclusive('\n');

// Read into ArrayList
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try reader.appendRemaining(allocator, &list, std.math.maxInt(usize));
```

### Key Operations
- `takeByte()` - Read single byte (advances position)
- `peekByte()` - Look at next byte (doesn't advance)
- `takeDelimiterInclusive('\n')` - Read line including newline
- `takeInt(u32, .little)` - Read binary integer
- `readSliceAll(buffer)` - Fill entire buffer

### ⚠️ Critical: Peek vs Take
```zig
const byte = try reader.peekByte();  // Position: 0
const same = try reader.peekByte();  // Position: 0 (same byte!)
reader.toss(1);                      // Position: 1

const byte2 = try reader.takeByte(); // Position: 1 (automatically advances)
```

---

## Overview

`std.Io.Reader` is Zig's buffered input interface introduced in version 0.15-0.16 as part of a major I/O overhaul. Unlike the old generic `std.io.Reader(T)`, the new `Reader` is a concrete, non-generic type that uses a buffer-over-vtable design for better performance and explicit resource management.

**Key Characteristics:**
- **Non-generic**: Single concrete type instead of generic `Reader(T)`
- **Buffered by default**: Buffer sits in the interface, not the implementation
- **Peek/Take pattern**: Separate operations for looking ahead vs consuming data
- **Zero-cost when buffered**: Operations on buffered data don't call vtable functions
- **Flexible backends**: Works with any backend implementing the VTable interface

**When to use Reader:**
- Reading files, network sockets, or memory buffers
- Parsing binary protocols or text formats
- Any scenario requiring buffered input with lookahead

## Critical Concept: Peek vs Take

⚠️ **IMPORTANT**: Reader has two main patterns for accessing data:

**Peek functions** - Look at data without consuming it:
- `peek()`, `peekByte()`, `peekArray()`, `peekInt()`, etc.
- Don't advance the read position
- Useful for lookahead and decision-making
- Must call `toss()` to advance position later

**Take functions** - Read and consume data:
- `take()`, `takeByte()`, `takeArray()`, `takeInt()`, etc.
- Automatically advance the read position
- Equivalent to `peek()` + `toss()`

```zig
// Lookahead pattern
const first = try reader.peekByte();
if (first == '#') {
    reader.toss(1);  // Skip the comment marker
    // Handle comment...
}

// Consume pattern
const byte = try reader.takeByte();  // Read and advance
```

## Basic Usage Examples

### Example 1: Reading from a Fixed Buffer

```zig
const std = @import("std");

pub fn main() !void {
    const data = "Hello, World!\n";
    var reader = std.Io.Reader.fixed(data);

    // Peek without consuming
    const first_char = try reader.peekByte();
    std.debug.print("First char: {c}\n", .{first_char});

    // Take and consume
    const hello = try reader.take(5);
    std.debug.print("Read: {s}\n", .{hello});

    // Remaining data
    const rest = try reader.peek(100);
    std.debug.print("Rest: {s}\n", .{rest});
}
```

### Example 2: Reading from a File with Io.Threaded

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create an I/O backend
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Open a file
    const dir = std.Io.Dir.cwd();
    const file = try dir.openFile(io, "input.txt", .{});
    defer file.close(io);

    // Get a reader and use it
    var buffer: [4096]u8 = undefined;
    var reader = file.reader(&buffer);

    // Read line by line
    while (true) {
        const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        std.debug.print("Line: {s}", .{line});
    }
}
```

### Example 3: Reading Binary Data

```zig
const std = @import("std");

pub fn main() !void {
    // Simulated binary data
    var buffer: [1024]u8 = undefined;
    var reader = std.Io.Reader.fixed(&buffer);

    // Read structured binary data
    const magic = try reader.takeInt(u32, .little);
    const version = try reader.takeInt(u16, .big);
    const flags = try reader.takeByte();

    // Read fixed-size array
    const uuid = try reader.takeArray(16);

    std.debug.print("Magic: 0x{x}, Version: {}, Flags: 0x{x}\n",
        .{magic, version, flags});
}
```

## Fields

`vtable: *const VTable`

Pointer to the virtual function table that defines the actual read implementation. The VTable contains function pointers for `readVec`, `discard`, and `rebase` operations.

------

`buffer: []u8`

The buffer where data is accumulated from the underlying resource. Data between `seek` and `end` contains valid buffered bytes.

------

`seek: usize`

Number of bytes which have been consumed from `buffer`. Index of the next byte to be read.

------

`end: usize`

In `buffer` before this are buffered bytes, after this is `undefined`. Marks the boundary between valid data and unused buffer space.

## Nested Types

- **Hashed**: Reader that computes a hash of all read data
- **Limited**: Reader that limits how many bytes can be read
- **VTable**: Virtual function table defining the reader's actual behavior

## Special Reader Instances

`ending: *Reader`

A reader that immediately returns `error.EndOfStream` on any read operation.

------

`ending_instance: Reader`

Static instance of the ending reader. This is generally safe to `@constCast` because it has an empty buffer, so there is not really a way to accidentally attempt mutation of these fields.

------

`failing: Reader`

A reader that returns `error.ReadFailed` on any read operation.

## Core Reading Functions - Take Pattern

These functions read data and automatically advance the read position.

### `pub fn takeByte(r: *Reader) Error!u8`

Reads 1 byte from the stream or returns `error.EndOfStream`. Automatically advances the read position.

**Example:**
```zig
const byte = try reader.takeByte();
std.debug.print("Read: {c}\n", .{byte});
```

------

### `pub fn takeByteSigned(r: *Reader) Error!i8`

Same as `takeByte` except the returned byte is signed.

------

### `pub fn take(r: *Reader, n: usize) Error![]u8`

Equivalent to `peek` followed by `toss`. Returns the next `n` bytes from the stream and advances the read position by `n`.

**Example:**
```zig
const data = try reader.take(10);
// Position advanced by 10 bytes
```

------

### `pub fn takeArray(r: *Reader, comptime n: usize) Error!*[n]u8`

Returns the next `n` bytes from the stream as an array, filling the buffer as necessary and advancing the seek position `n` bytes.

**Example:**
```zig
const header = try reader.takeArray(16);
// header is *[16]u8
```

------

### `pub inline fn takeInt(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`

Reads an integer from the stream in the specified byte order. Asserts the buffer was initialized with a capacity at least `@bitSizeOf(T) / 8`. Advances the read position.

**Example:**
```zig
const value = try reader.takeInt(u32, .little);
const big_val = try reader.takeInt(u64, .big);
```

------

### `pub inline fn takeStruct(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`

Reads a struct from the stream in the specified byte order. Asserts the buffer was initialized with a capacity at least `@sizeOf(T)`. Advances the read position.

------

### `pub fn takeStructPointer(r: *Reader, comptime T: type) Error!*align(1) T`

Obtains an unaligned pointer to the beginning of the stream, reinterpreted as a pointer to the provided type, advancing the seek position.

------

### `pub fn takeVarInt(r: *Reader, comptime Int: type, endian: std.builtin.Endian, n: usize) Error!Int`

Reads a variable-length integer. Asserts the buffer was initialized with a capacity at least `n`.

------

### `pub fn takeLeb128(r: *Reader, comptime T: type) TakeLeb128Error!T`

Read a single LEB128 value as type T, or `error.Overflow` if the value cannot fit.

------

### `pub fn takeEnum(r: *Reader, comptime Enum: type, endian: std.builtin.Endian) TakeEnumError!Enum`

Reads an integer with the same size as the given enum's tag type. If the integer matches an enum tag, casts the integer to the enum tag and returns it. Otherwise, returns `error.InvalidEnumTag`.

------

### `pub fn takeEnumNonexhaustive(r: *Reader, comptime Enum: type, endian: std.builtin.Endian) Error!Enum`

Reads an integer with the same size as the given nonexhaustive enum's tag type.

## Delimiter Reading Functions - Take Pattern

### `pub fn takeDelimiter(r: *Reader, delimiter: u8) error{ ReadFailed, StreamTooLong }!?[]u8`

Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position past the delimiter.

------

### `pub fn takeDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`

Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position up to (but not past) the delimiter.

**Example:**
```zig
// Read line without the newline
const line = try reader.takeDelimiterExclusive('\n');
reader.toss(1);  // Skip the newline
```

------

### `pub fn takeDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`

Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position past the delimiter.

**Example:**
```zig
// Read line with the newline
const line = try reader.takeDelimiterInclusive('\n');
```

------

### `pub fn takeSentinel(r: *Reader, comptime sentinel: u8) DelimiterError![:sentinel]u8`

Returns a slice of the next bytes of buffered data from the stream until `sentinel` is found, advancing the seek position past the sentinel.

## Core Reading Functions - Peek Pattern

These functions look at data without advancing the read position.

### `pub fn peekByte(r: *Reader) Error!u8`

Returns the next byte from the stream or returns `error.EndOfStream`. Does not advance the read position.

**Example:**
```zig
const byte = try reader.peekByte();
// Position unchanged - same byte available on next peek
```

------

### `pub fn peek(r: *Reader, n: usize) Error![]u8`

Returns the next `n` bytes from the stream, filling the buffer as necessary. Does not advance the read position.

**Safe, but strict:**
- **Demands** exactly `n` bytes
- Returns `error.EndOfStream` if fewer than `n` bytes available
- Memory-safe, no buffer overflows possible
- **Best for:** "I need exactly N bytes or it's an error" (like reading a fixed-size header)

**Example:**
```zig
// Reading a 16-byte header - MUST be exactly 16 bytes
const header = try reader.peek(16);  // Errors if <16 bytes available
// Position unchanged
reader.toss(5);  // Manually advance if needed
```

------

### `pub fn peekArray(r: *Reader, comptime n: usize) Error!*[n]u8`

Returns the next `n` bytes from the stream as an array, filling the buffer as necessary, without advancing the seek position.

------

### `pub inline fn peekInt(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`

Looks at the next integer without consuming it. Asserts the buffer was initialized with a capacity at least `@bitSizeOf(T) / 8`.

**Example:**
```zig
const value = try reader.peekInt(u32, .little);
// Position unchanged
```

------

### `pub inline fn peekStruct(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`

Looks at the next struct without consuming it. Asserts the buffer was initialized with a capacity at least `@sizeOf(T)`.

------

### `pub fn peekStructPointer(r: *Reader, comptime T: type) Error!*align(1) T`

Obtains an unaligned pointer to the beginning of the stream, reinterpreted as a pointer to the provided type, without advancing the seek position.

------

### `pub fn peekGreedy(r: *Reader, n: usize) Error![]u8`

Returns all the next buffered bytes, after filling the buffer to ensure it contains at least `n` bytes.

**Safe, may do I/O:**
- Tries to fill buffer with up to `n` bytes from the stream
- Returns whatever it successfully gets (could be less than `n`)
- Only errors on I/O failures (network down, disk error, not on EndOfStream)
- Memory-safe, no buffer overflows possible
- **Best for:** "Try to get up to N bytes from a stream"

**Example:**
```zig
const data = try reader.peekGreedy(1024);
// Safe: might get 1 byte, might get 1024, returns what's available
// Only errors on actual I/O failure, not on short reads
```

## Delimiter Peek Functions

### `pub fn peekDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`

Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, without advancing the seek position.

------

### `pub fn peekDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`

Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, without advancing the seek position.

------

### `pub fn peekSentinel(r: *Reader, comptime sentinel: u8) DelimiterError![:sentinel]u8`

Returns a slice of the next bytes of buffered data from the stream until `sentinel` is found, without advancing the seek position.

## Buffer Management Functions

### `pub fn buffered(r: *Reader) []u8`

Returns a slice of the buffered data that hasn't been consumed yet (from `seek` to `end`).

**Safest method - never errors:**
- Just returns what's already in the buffer (no I/O operations)
- Can return empty slice if nothing buffered yet
- Memory-safe, no buffer overflows possible
- **Best for:** "Give me whatever you have right now"

**Example:**
```zig
const available = reader.buffered();
// Safe: returns 0 to buffer.len bytes, never errors
```

------

### `pub fn bufferedLen(r: *const Reader) usize`

Returns the number of bytes currently buffered and available to read.

------

### `pub fn toss(r: *Reader, n: usize) void`

Skips the next `n` bytes from the stream, advancing the seek position. This is typically and safely used after `peek`.

**Example:**
```zig
const data = try reader.peek(100);
// Examine data...
reader.toss(50);  // Skip first 50 bytes
```

------

### `pub fn tossBuffered(r: *Reader) void`

Equivalent to `toss(r.bufferedLen())`. Discards all currently buffered data.

------

### `pub fn fill(r: *Reader, n: usize) Error!void`

Fills the buffer such that it contains at least `n` bytes, without advancing the seek position.

------

### `pub fn fillMore(r: *Reader) Error!void`

Without advancing the seek position, does exactly one underlying read, filling the buffer as much as possible. This may result in zero bytes added to the buffer, which is not an end of stream condition. End of stream is communicated via returning `error.EndOfStream`.

------

### `pub fn rebase(r: *Reader, capacity: usize) RebaseError!void`

Ensures `capacity` data can be buffered without rebasing.

## Memory Allocation Functions

### `pub fn allocRemaining(r: *Reader, gpa: Allocator, limit: Limit) LimitedAllocError![]u8`

Transfers all bytes from the current position to the end of the stream, up to `limit`, returning them as a caller-owned allocated slice.

**Example:**
```zig
const data = try reader.allocRemaining(allocator, 1024 * 1024);
defer allocator.free(data);
```

------

### `pub fn allocRemainingAlignedSentinel( r: *Reader, gpa: Allocator, limit: Limit, comptime alignment: std.mem.Alignment, comptime sentinel: ?u8, ) LimitedAllocError!(if (sentinel) |s| [:s]align(alignment.toByteUnits()) u8 else []align(alignment.toByteUnits()) u8)`

Allocates remaining data with specific alignment and optional sentinel.

------

### `pub fn appendRemaining( r: *Reader, gpa: Allocator, list: *ArrayList(u8), limit: Limit, ) LimitedAllocError!void`

Transfers all bytes from the current position to the end of the stream, up to `limit`, appending them to `list`.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try reader.appendRemaining(allocator, &list, 1024 * 1024);
```

------

### `pub fn appendRemainingAligned( r: *Reader, gpa: Allocator, comptime alignment: std.mem.Alignment, list: *std.array_list.Aligned(u8, alignment), limit: Limit, ) LimitedAllocError!void`

Transfers all bytes from the current position to the end of the stream, up to `limit`, appending them to `list`.

------

### `pub fn appendRemainingUnlimited(r: *Reader, gpa: Allocator, list: *ArrayList(u8)) UnlimitedAllocError!void`

Appends all remaining bytes without a limit.

## Read Into Buffer Functions

### `pub fn readAlloc(r: *Reader, allocator: Allocator, len: usize) ReadAllocError![]u8`

Shortcut for calling `readSliceAll` with a buffer provided by `allocator`.

**Example:**
```zig
const data = try reader.readAlloc(allocator, 1024);
defer allocator.free(data);
```

------

### `pub fn readSliceAll(r: *Reader, buffer: []u8) Error!void`

Fill `buffer` with the next `buffer.len` bytes from the stream, advancing the seek position.

**Example:**
```zig
var buffer: [1024]u8 = undefined;
try reader.readSliceAll(&buffer);
// buffer now contains 1024 bytes
```

------

### `pub inline fn readSliceEndian( r: *Reader, comptime Elem: type, buffer: []Elem, endian: std.builtin.Endian, ) Error!void`

Fill `buffer` with the next `buffer.len` elements from the stream, advancing the seek position.

------

### `pub inline fn readSliceEndianAlloc( r: *Reader, allocator: Allocator, comptime Elem: type, len: usize, endian: std.builtin.Endian, ) ReadAllocError![]Elem`

The function is inline to avoid the dead code in case `endian` is comptime-known and matches host endianness.

------

### `pub fn readSliceShort(r: *Reader, buffer: []u8) ShortError!usize`

Fill `buffer` with the next `buffer.len` bytes from the stream, advancing the seek position. Returns number of bytes actually read (may be less than buffer.len).

## Discard Functions

### `pub fn discard(r: *Reader, limit: Limit) Error!usize`

Discards up to `limit` bytes from the stream, returning the number of bytes discarded.

------

### `pub fn discardAll(r: *Reader, n: usize) Error!void`

Skips the next `n` bytes from the stream, advancing the seek position.

------

### `pub fn discardAll64(r: *Reader, n: u64) Error!void`

Skips the next `n` bytes from the stream (64-bit version).

------

### `pub fn discardShort(r: *Reader, n: usize) ShortError!usize`

Skips the next `n` bytes from the stream, advancing the seek position. Returns number of bytes actually skipped.

------

### `pub fn discardRemaining(r: *Reader) ShortError!usize`

Consumes the stream until the end, ignoring all the data, returning the number of bytes discarded.

------

### `pub fn discardDelimiterExclusive(r: *Reader, delimiter: u8) ShortError!usize`

Reads from the stream until specified byte is found, discarding all data, excluding the delimiter.

------

### `pub fn discardDelimiterInclusive(r: *Reader, delimiter: u8) Error!usize`

Reads from the stream until specified byte is found, discarding all data, including the delimiter.

------

### `pub fn discardDelimiterLimit(r: *Reader, delimiter: u8, limit: Limit) DiscardDelimiterLimitError!usize`

Reads from the stream until specified byte is found, discarding all data, excluding the delimiter.

## Vectorized I/O Functions

### `pub fn readVec(r: *Reader, data: [][]u8) Error!usize`

Writes bytes from the internally tracked stream position to `data`.

------

### `pub fn readVecAll(r: *Reader, data: [][]u8) Error!void`

Reads into multiple buffers, ensuring all are filled.

------

### `pub fn writableVector(r: *Reader, buffer: [][]u8, data: []const []u8) Error!struct { usize, usize }`

Helper for vectorized writes.

------

### `pub fn writableVectorPosix(r: *Reader, buffer: []std.posix.iovec, data: []const []u8) Error!struct { usize, usize }`

POSIX-specific vectorized I/O helper.

------

### `pub fn writableVectorWsa( r: *Reader, buffer: []std.os.windows.ws2_32.WSABUF, data: []const []u8, ) Error!struct { usize, usize }`

Windows WSA-specific vectorized I/O helper.

## Streaming Functions

### `pub fn stream(r: *Reader, w: *Writer, limit: Limit) StreamError!usize`

Streams data from reader to writer up to `limit` bytes.

**Example:**
```zig
const bytes_copied = try reader.stream(&writer, 1024);
```

------

### `pub fn streamExact(r: *Reader, w: *Writer, n: usize) StreamError!void`

"Pump" exactly `n` bytes from the reader to the writer.

------

### `pub fn streamExact64(r: *Reader, w: *Writer, n: u64) StreamError!void`

"Pump" exactly `n` bytes from the reader to the writer (64-bit version).

------

### `pub fn streamExactPreserve(r: *Reader, w: *Writer, preserve_len: usize, n: usize) StreamError!void`

"Pump" exactly `n` bytes from the reader to the writer.

------

### `pub fn streamRemaining(r: *Reader, w: *Writer) StreamRemainingError!usize`

"Pump" data from the reader to the writer, handling `error.EndOfStream` as a success case.

------

### `pub fn streamDelimiter(r: *Reader, w: *Writer, delimiter: u8) StreamError!usize`

Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

------

### `pub fn streamDelimiterEnding( r: *Reader, w: *Writer, delimiter: u8, ) StreamRemainingError!usize`

Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

------

### `pub fn streamDelimiterLimit( r: *Reader, w: *Writer, delimiter: u8, limit: Limit, ) StreamDelimiterLimitError!usize`

Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

## Specialized Reader Constructors

### `pub fn fixed(buffer: []const u8) Reader`

Constructs a `Reader` such that it will read from `buffer` and then end.

**Example:**
```zig
const data = "Hello, World!";
var reader = std.Io.Reader.fixed(data);
const byte = try reader.takeByte();  // 'H'
```

------

### `pub fn hashed(r: *Reader, hasher: anytype, buffer: []u8) Hashed(@TypeOf(hasher))`

Creates a reader that computes a hash of all data read.

------

### `pub fn limited(r: *Reader, limit: Limit, buffer: []u8) Limited`

Creates a reader that limits how many bytes can be read.

## Internal/Advanced Functions

### `pub fn defaultDiscard(r: *Reader, limit: Limit) Error!usize`

Default implementation of discard operation.

------

### `pub fn defaultReadVec(r: *Reader, data: [][]u8) Error!usize`

Writes to `Reader.buffer` or `data`, whichever has larger capacity.

------

### `pub fn defaultRebase(r: *Reader, capacity: usize) RebaseError!void`

Default implementation of buffer rebase operation.

`pub fn discard(r: *Reader, limit: Limit) Error!usize`  

`pub fn discardAll(r: *Reader, n: usize) Error!void`  
Skips the next `n` bytes from the stream, advancing the seek position.

`pub fn discardAll64(r: *Reader, n: u64) Error!void`  

`pub fn discardDelimiterExclusive(r: *Reader, delimiter: u8) ShortError!usize`  
Reads from the stream until specified byte is found, discarding all data, excluding the delimiter.

`pub fn discardDelimiterInclusive(r: *Reader, delimiter: u8) Error!usize`  
Reads from the stream until specified byte is found, discarding all data, including the delimiter.

`pub fn discardDelimiterLimit(r: *Reader, delimiter: u8, limit: Limit) DiscardDelimiterLimitError!usize`  
Reads from the stream until specified byte is found, discarding all data, excluding the delimiter.

`pub fn discardRemaining(r: *Reader) ShortError!usize`  
Consumes the stream until the end, ignoring all the data, returning the number of bytes discarded.

`pub fn discardShort(r: *Reader, n: usize) ShortError!usize`  
Skips the next `n` bytes from the stream, advancing the seek position.

`pub fn fill(r: *Reader, n: usize) Error!void`  
Fills the buffer such that it contains at least `n` bytes, without advancing the seek position.

`pub fn fillMore(r: *Reader) Error!void`  
Without advancing the seek position, does exactly one underlying read, filling the buffer as much as possible. This may result in zero bytes added to the buffer, which is not an end of stream condition. End of stream is communicated via returning `error.EndOfStream`.

`pub fn fixed(buffer: []const u8) Reader`  
Constructs a `Reader` such that it will read from `buffer` and then end.

`pub fn hashed(r: *Reader, hasher: anytype, buffer: []u8) Hashed(@TypeOf(hasher))`  

`pub fn limited(r: *Reader, limit: Limit, buffer: []u8) Limited`  

`pub fn peek(r: *Reader, n: usize) Error![]u8`  
Returns the next `n` bytes from the stream, filling the buffer as necessary.

`pub fn peekArray(r: *Reader, comptime n: usize) Error!*[n]u8`  
Returns the next `n` bytes from the stream as an array, filling the buffer as necessary, without advancing the seek position.

`pub fn peekByte(r: *Reader) Error!u8`  
Returns the next byte from the stream or returns `error.EndOfStream`.

`pub fn peekDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`  
Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, without advancing the seek position.

`pub fn peekDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`  
Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, without advancing the seek position.

`pub fn peekGreedy(r: *Reader, n: usize) Error![]u8`  
Returns all the next buffered bytes, after filling the buffer to ensure it contains at least `n` bytes.

`pub inline fn peekInt(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`  
Asserts the buffer was initialized with a capacity at least `@bitSizeOf(T) / 8`.

`pub fn peekSentinel(r: *Reader, comptime sentinel: u8) DelimiterError![:sentinel]u8`  
Returns a slice of the next bytes of buffered data from the stream until `sentinel` is found, without advancing the seek position.

`pub inline fn peekStruct(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`  
Asserts the buffer was initialized with a capacity at least `@sizeOf(T)`.

`pub fn peekStructPointer(r: *Reader, comptime T: type) Error!*align(1) T`  
Obtains an unaligned pointer to the beginning of the stream, reinterpreted as a pointer to the provided type, without advancing the seek position.

`pub fn readAlloc(r: *Reader, allocator: Allocator, len: usize) ReadAllocError![]u8`  
Shortcut for calling `readSliceAll` with a buffer provided by `allocator`.

`pub fn readSliceAll(r: *Reader, buffer: []u8) Error!void`  
Fill `buffer` with the next `buffer.len` bytes from the stream, advancing the seek position.

`pub inline fn readSliceEndian( r: *Reader, comptime Elem: type, buffer: []Elem, endian: std.builtin.Endian, ) Error!void`  
Fill `buffer` with the next `buffer.len` bytes from the stream, advancing the seek position.

`pub inline fn readSliceEndianAlloc( r: *Reader, allocator: Allocator, comptime Elem: type, len: usize, endian: std.builtin.Endian, ) ReadAllocError![]Elem`  
The function is inline to avoid the dead code in case `endian` is comptime-known and matches host endianness.

`pub fn readSliceShort(r: *Reader, buffer: []u8) ShortError!usize`  
Fill `buffer` with the next `buffer.len` bytes from the stream, advancing the seek position.

`pub fn readVec(r: *Reader, data: [][]u8) Error!usize`  
Writes bytes from the internally tracked stream position to `data`.

`pub fn readVecAll(r: *Reader, data: [][]u8) Error!void`  

`pub fn rebase(r: *Reader, capacity: usize) RebaseError!void`  
Ensures `capacity` data can be buffered without rebasing.

`pub fn stream(r: *Reader, w: *Writer, limit: Limit) StreamError!usize`  

`pub fn streamDelimiter(r: *Reader, w: *Writer, delimiter: u8) StreamError!usize`  
Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

`pub fn streamDelimiterEnding( r: *Reader, w: *Writer, delimiter: u8, ) StreamRemainingError!usize`  
Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

`pub fn streamDelimiterLimit( r: *Reader, w: *Writer, delimiter: u8, limit: Limit, ) StreamDelimiterLimitError!usize`  
Appends to `w` contents by reading from the stream until `delimiter` is found. Does not write the delimiter itself.

`pub fn streamExact(r: *Reader, w: *Writer, n: usize) StreamError!void`  
"Pump" exactly `n` bytes from the reader to the writer.

`pub fn streamExact64(r: *Reader, w: *Writer, n: u64) StreamError!void`  
"Pump" exactly `n` bytes from the reader to the writer.

`pub fn streamExactPreserve(r: *Reader, w: *Writer, preserve_len: usize, n: usize) StreamError!void`  
"Pump" exactly `n` bytes from the reader to the writer.

`pub fn streamRemaining(r: *Reader, w: *Writer) StreamRemainingError!usize`  
"Pump" data from the reader to the writer, handling `error.EndOfStream` as a success case.

`pub fn take(r: *Reader, n: usize) Error![]u8`  
Equivalent to `peek` followed by `toss`.

`pub fn takeArray(r: *Reader, comptime n: usize) Error!*[n]u8`  
Returns the next `n` bytes from the stream as an array, filling the buffer as necessary and advancing the seek position `n` bytes.

`pub fn takeByte(r: *Reader) Error!u8`  
Reads 1 byte from the stream or returns `error.EndOfStream`.

`pub fn takeByteSigned(r: *Reader) Error!i8`  
Same as `takeByte` except the returned byte is signed.

`pub fn takeDelimiter(r: *Reader, delimiter: u8) error{ ReadFailed, StreamTooLong }!?[]u8`  
Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position past the delimiter.

`pub fn takeDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`  
Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position up to (but not past) the delimiter.

`pub fn takeDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8`  
Returns a slice of the next bytes of buffered data from the stream until `delimiter` is found, advancing the seek position past the delimiter.

`pub fn takeEnum(r: *Reader, comptime Enum: type, endian: std.builtin.Endian) TakeEnumError!Enum`  
Reads an integer with the same size as the given enum's tag type. If the integer matches an enum tag, casts the integer to the enum tag and returns it. Otherwise, returns `error.InvalidEnumTag`.

`pub fn takeEnumNonexhaustive(r: *Reader, comptime Enum: type, endian: std.builtin.Endian) Error!Enum`  
Reads an integer with the same size as the given nonexhaustive enum's tag type.

`pub inline fn takeInt(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`  
Asserts the buffer was initialized with a capacity at least `@bitSizeOf(T) / 8`.

`pub fn takeLeb128(r: *Reader, comptime T: type) TakeLeb128Error!T`  
Read a single LEB128 value as type T, or `error.Overflow` if the value cannot fit.

`pub fn takeSentinel(r: *Reader, comptime sentinel: u8) DelimiterError![:sentinel]u8`  
Returns a slice of the next bytes of buffered data from the stream until `sentinel` is found, advancing the seek position past the sentinel.

`pub inline fn takeStruct(r: *Reader, comptime T: type, endian: std.builtin.Endian) Error!T`  
Asserts the buffer was initialized with a capacity at least `@sizeOf(T)`.

`pub fn takeStructPointer(r: *Reader, comptime T: type) Error!*align(1) T`  
Obtains an unaligned pointer to the beginning of the stream, reinterpreted as a pointer to the provided type, advancing the seek position.

`pub fn takeVarInt(r: *Reader, comptime Int: type, endian: std.builtin.Endian, n: usize) Error!Int`  
Asserts the buffer was initialized with a capacity at least `n`.

`pub fn toss(r: *Reader, n: usize) void`  
Skips the next `n` bytes from the stream, advancing the seek position. This is typically and safely used after `peek`.

`pub fn tossBuffered(r: *Reader) void`  
Equivalent to `toss(r.bufferedLen())`.

`pub fn writableVector(r: *Reader, buffer: [][]u8, data: []const []u8) Error!struct { usize, usize }`  

`pub fn writableVectorPosix(r: *Reader, buffer: []std.posix.iovec, data: []const []u8) Error!struct { usize, usize }`  

`pub fn writableVectorWsa( r: *Reader, buffer: []std.os.windows.ws2_32.WSABUF, data: []const []u8, ) Error!struct { usize, usize }`  

## Error Sets

### `Error`

General read errors that may occur during read operations.

------

### `DelimiterError`

Errors specific to delimiter-based reading (when delimiter is not found or buffer issues).

------

### `DiscardDelimiterLimitError`

Errors for delimiter-limited discard operations.

------

### `ShortError`

Errors for operations that may perform short reads.

------

### `TakeEnumError`

Errors when reading enum values (includes `error.InvalidEnumTag`).

------

### `TakeLeb128Error`

Errors when reading LEB128 encoded integers (includes `error.Overflow`).

------

### `ReadAllocError`

Errors combining read errors with allocation errors.

------

### `LimitedAllocError`

Errors for limited allocation operations.

------

### `UnlimitedAllocError`

Errors for unlimited allocation operations.

------

### `RebaseError`

Errors when rebasing the buffer.

------

### `StreamError`

Errors when streaming data to a writer.

------

### `StreamRemainingError`

Errors for streaming remaining data.

------

### `StreamDelimiterLimitError`

Errors for delimiter-limited streaming.

## Debug Checklist

If your code doesn't compile, check:

1. ✅ Did you pass `io` to file operations?
2. ✅ Are you using the right Reader type?
   - `std.Io.Reader` - Standalone reader
   - `File.Reader` - File-specific reader (different API!)
3. ✅ Did you confuse `peek` vs `take`?
   - `peek` = look without consuming
   - `take` = read and advance position
4. ✅ Did you call `toss()` after `peek()` if you want to advance?
5. ✅ Did you handle `error.EndOfStream` properly?
6. ✅ Did you provide a large enough buffer for operations like `peekInt()`?
7. ✅ Using `peek()` to get remaining data?
   ```zig
   // ❌ DON'T: peek() demands exactly N bytes, errors if not available
   const rest = try reader.peek(100);

   // ✅ DO: Use buffered() for "whatever's available" (never errors)
   const rest = reader.buffered();

   // ✅ OR: Use peekGreedy() for streams (returns up to N bytes)
   const rest = try reader.peekGreedy(100);
   ```
   See `buffered()`, `peekGreedy()`, and `peek()` method docs for detailed safety info.

## Common Patterns

### Pattern 1: Line-by-line Reading

```zig
while (true) {
    const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
        error.EndOfStream => break,
        else => return err,
    };
    // Process line...
}
```

### Pattern 2: Binary Protocol Parsing

```zig
// Peek at header to determine message type
const msg_type = try reader.peekByte();

switch (msg_type) {
    0x01 => {
        reader.toss(1);  // Consume type byte
        const len = try reader.takeInt(u32, .little);
        const payload = try reader.take(len);
        // Handle type 1 message...
    },
    0x02 => {
        reader.toss(1);
        // Handle type 2 message...
    },
    else => return error.UnknownMessageType,
}
```

### Pattern 3: Lookahead Parsing

```zig
// Check if next is a comment
const first = try reader.peekByte();
if (first == '#') {
    // Skip comment line
    _ = try reader.discardDelimiterInclusive('\n');
} else {
    // Parse normal line
    const line = try reader.takeDelimiterExclusive('\n');
}
```

### Pattern 4: Reading Entire File to ArrayList

```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try reader.appendRemaining(allocator, &list, std.math.maxInt(usize));
// list.items now contains entire file
```

## Performance Tips

1. **Size your buffer appropriately**: Larger buffers reduce syscalls but use more memory (4096 is common)
2. **Use `peek` for lookahead**: Avoid re-reading data by peeking ahead before making decisions
3. **Prefer `take` over `peek + toss`**: Unless you genuinely need lookahead
4. **Use `readSliceAll` for bulk reads**: When you know exactly how many bytes you need
5. **Consider buffer capacity**: Ensure buffer is large enough for `peekInt()`, `takeStruct()`, etc.

## See Also

- `std.Io.Writer` - Companion type for buffered writing
- `std.Io.Threaded` - Thread-based I/O backend
- `std.Io.Evented` - Event-based I/O backend (async)
- `std.Io.File` - File operations with the new I/O interface
