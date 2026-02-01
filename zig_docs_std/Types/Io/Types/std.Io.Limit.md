# std.Io.Limit

## Quick Start

### Limiting Read Operations

```zig
const std = @import("std");

// Limit reads to 1024 bytes
const limit = std.Io.Limit.limited(1024);

var buffer: [4096]u8 = undefined;
const safe_slice = limit.slice(&buffer); // Returns buffer[0..1024]

// Read with limit
const bytes_read = try reader.readAtLeast(safe_slice, 1);
```

### Tracking Remaining Capacity

```zig
const std = @import("std");

var remaining = std.Io.Limit.limited(1000);

// Process data in chunks
while (remaining.nonzero()) {
    const chunk_size = remaining.minInt(256); // Read up to 256 bytes
    const chunk = try readChunk(chunk_size);

    // Reduce limit
    remaining = remaining.subtract(chunk.len) orelse {
        return error.LimitExceeded;
    };
}
```

### Unlimited Reading

```zig
const std = @import("std");

// No limit - read everything
const limit = std.Io.Limit.unlimited;

var buffer: [8192]u8 = undefined;
const full_buffer = limit.slice(&buffer); // Returns entire buffer
```

⚠️ **Critical**: Always check if a limit is exceeded before continuing operations. Use `subtract()` which returns `null` when the limit would be exceeded, preventing buffer overruns.

---

## Overview

`std.Io.Limit` is a type-safe abstraction for representing size constraints in I/O operations. It provides a way to enforce maximum read/write sizes, track remaining capacity, and safely slice buffers to respect limits. The type distinguishes between "nothing" (0 bytes), specific byte limits, and "unlimited" (maximum usize).

**Key Characteristics:**
- **Type Safety**: Enum with tagged values prevents accidental integer overflow
- **Special Values**: Dedicated `.nothing`, `.unlimited`, and numeric limits
- **Buffer Safety**: Helper methods automatically constrain slices to respect limits
- **Composable**: Min/max operations and arithmetic for limit management

**When to use:**
- Enforcing maximum message/request sizes to prevent DoS attacks
- Implementing quota systems (bandwidth limits, file size limits)
- Safely reading untrusted input with bounded memory usage
- Pagination and chunked processing

## Enum Values

`nothing = 0`

Represents a limit of zero bytes. No data transfer is allowed.

**Use case:**
- Disabled features or closed connections
- Signaling "do not read/write"

------

`unlimited = std.math.maxInt(usize)`

Represents no practical limit. Operations can use the maximum addressable memory.

**Use case:**
- Trusted input sources
- Internal operations where limits are managed elsewhere
- Configuration defaults meaning "no restriction"

------

`_`

The catch-all variant for specific numeric limits between 0 and `std.math.maxInt(usize)`.

**Example:** `std.Io.Limit.limited(1024)` creates a limit of 1024 bytes.

## Constructor Functions

### `pub fn countVec(data: []const []const u8) Limit`

Counts the total bytes across multiple slices and returns a `Limit` representing that count.

**Example:**
```zig
const slices = [_][]const u8{ "Hello", " ", "World" };
const total = std.Io.Limit.countVec(&slices);
// total == Limit.limited(11)
```

------

### `pub fn limited(n: usize) Limit`

Creates a `Limit` with a specific byte count. If `n == std.math.maxInt(usize)`, returns `.unlimited`.

**Example:**
```zig
const limit = std.Io.Limit.limited(4096); // 4KB limit
```

------

### `pub fn limited64(n: u64) Limit`

Creates a `Limit` from a 64-bit value. If `n > std.math.maxInt(usize)`, returns `.unlimited`.

**Use case:** Parsing limits from network protocols or config files that use 64-bit sizes.

**Example:**
```zig
const limit = std.Io.Limit.limited64(max_file_size_from_config);
```

## Comparison & Arithmetic Functions

### `pub fn min(a: Limit, b: Limit) Limit`

Returns the smaller of two limits. `.nothing` is smallest, `.unlimited` is largest.

**Example:**
```zig
const user_limit = std.Io.Limit.limited(2048);
const system_limit = std.Io.Limit.limited(1024);
const effective = std.Io.Limit.min(user_limit, system_limit); // 1024
```

------

### `pub fn minInt(l: Limit, n: usize) usize`

Returns the minimum of the limit and an integer `n`. If limit is `.unlimited`, returns `n`.

**Example:**
```zig
const limit = std.Io.Limit.limited(100);
const chunk_size = limit.minInt(256); // Returns 100
```

------

### `pub fn minInt64(l: Limit, n: u64) usize`

64-bit version of `minInt`. Clamps result to `usize` range.

------

### `pub fn subtract(l: Limit, amount: usize) ?Limit`

Reduces the limit by `amount` bytes. Returns `null` if the subtraction would underflow (amount > limit), allowing safe quota tracking.

**Example:**
```zig
var remaining = std.Io.Limit.limited(1000);

// Read 300 bytes
remaining = remaining.subtract(300) orelse return error.LimitExceeded;
// remaining now 700

// Try to read 800 bytes - would exceed!
remaining = remaining.subtract(800) orelse {
    std.debug.print("Cannot subtract 800 from 700\n", .{});
    return error.LimitExceeded;
};
```

## Query Functions

### `pub fn nonzero(l: Limit) bool`

Returns `true` if the limit allows at least one byte (not `.nothing`).

**Example:**
```zig
while (limit.nonzero()) {
    // Process data
    const read = try processChunk();
    limit = limit.subtract(read) orelse break;
}
```

------

### `pub fn toInt(l: Limit) ?usize`

Converts the limit to an integer, returning `null` for `.unlimited`.

**Use case:** When you need the numeric value but want to handle "unlimited" specially.

**Example:**
```zig
if (limit.toInt()) |max_bytes| {
    std.debug.print("Limited to {} bytes\n", .{max_bytes});
} else {
    std.debug.print("Unlimited\n", .{});
}
```

## Buffer Slicing Functions

### `pub fn slice(l: Limit, s: []u8) []u8`

Reduces a mutable slice to respect the limit. Returns a sub-slice of at most `limit` bytes.

**Example:**
```zig
var buffer: [4096]u8 = undefined;
const limit = std.Io.Limit.limited(1024);
const safe = limit.slice(&buffer); // Returns buffer[0..1024]
```

------

### `pub fn slice1(l: Limit, non_empty_buffer: []u8) []u8`

Like `slice()`, but leaves room for one extra byte above the limit. This allows distinguishing between "reached limit exactly" and "hit end-of-stream".

**Use case:** Reading delimited data where you need to detect if the delimiter is at exactly the limit or if there's more data.

**Example:**
```zig
const limit = std.Io.Limit.limited(100);
var buffer: [256]u8 = undefined;
const probe_slice = limit.slice1(&buffer); // Returns buffer[0..101]

const data = try reader.readUntilDelimiter(probe_slice, '\n');
if (data.len == 100) {
    // Hit limit - delimiter not found within 100 bytes
    return error.LineTooLong;
}
// Otherwise, found delimiter within limit
```

------

### `pub fn sliceConst(l: Limit, s: []const u8) []const u8`

Const version of `slice()` for read-only buffers.

**Example:**
```zig
const data: []const u8 = "Hello, World!";
const limit = std.Io.Limit.limited(5);
const truncated = limit.sliceConst(data); // Returns "Hello"
```

## Usage Patterns

### Request Size Limiting (DoS Prevention)

```zig
const std = @import("std");

pub fn handleRequest(reader: std.Io.Reader, io: std.Io) !void {
    const max_request_size = std.Io.Limit.limited(1024 * 1024); // 1 MB
    var remaining = max_request_size;

    var buffer: [8192]u8 = undefined;

    while (remaining.nonzero()) {
        const chunk_buf = remaining.slice(&buffer);
        const chunk = reader.interface.readAtLeast(chunk_buf, 1) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };

        remaining = remaining.subtract(chunk.len) orelse {
            return error.RequestTooLarge;
        };

        // Process chunk...
    }
}
```

### Quota-Based File Reading

```zig
const std = @import("std");

pub fn readWithQuota(file: std.Io.File, quota: std.Io.Limit, allocator: Allocator) ![]u8 {
    const max_size = quota.toInt() orelse return error.UnlimitedNotAllowed;

    var buffer = try allocator.alloc(u8, max_size);
    errdefer allocator.free(buffer);

    var reader = file.reader(...);
    const bytes_read = try reader.interface.readAll(quota.slice(buffer));

    return buffer[0..bytes_read];
}
```

## Debug Checklist

- ✅ **Null Check**: Did you handle `subtract()` returning `null`?
- ✅ **Unlimited Handling**: Does your code work correctly with `.unlimited`?
- ✅ **Zero Limit**: Does your code handle `.nothing` (zero limit) gracefully?
- ✅ **Buffer Size**: Is your buffer large enough for the limit plus any extra bytes (like `slice1`)?

## Performance Tips

1. **Use `minInt` for Chunking**: Efficiently calculate chunk sizes without branches
2. **Prefer `slice()` Over Manual Math**: Prevents off-by-one errors and is compiler-optimizable
3. **Check `nonzero()` Early**: Avoids unnecessary work when limit is exhausted
4. **Avoid `toInt()` in Hot Loops**: Use `minInt()` or `slice()` directly instead

## See Also

- `std.Io.Reader` - Uses limits for bounded reading
- `std.Io.Writer` - Can enforce write limits
- `std.io.limitedReader()` - Reader wrapper that enforces a limit
