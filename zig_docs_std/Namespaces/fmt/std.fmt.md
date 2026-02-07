# std.fmt

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all fmt features

## Quick Start

### Most Common Patterns

**Stack-Allocated Formatting (No Allocator)**
```zig
var buffer: [1024]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "Hello, {s}! You have {} messages.", .{"Alice", 42});
std.debug.print("{s}\n", .{result});
```

**Heap-Allocated Formatting**
```zig
const allocator = std.heap.page_allocator;
const message = try std.fmt.allocPrint(allocator, "User: {s}, Score: {d}", .{"Bob", 9001});
defer allocator.free(message);
```

**Parsing Integers**
```zig
const num = try std.fmt.parseInt(i32, "42", 10);           // Decimal
const hex_num = try std.fmt.parseInt(u32, "FF", 16);       // Hexadecimal
const bin_num = try std.fmt.parseInt(u8, "1010", 2);       // Binary
```

**Parsing Floats**
```zig
const pi = try std.fmt.parseFloat(f64, "3.14159");
const sci = try std.fmt.parseFloat(f32, "1.5e-10");
```

**Hex Encoding/Decoding**
```zig
const bytes = "Hello";
const hex = std.fmt.bytesToHex(bytes, .lower);  // "48656c6c6f"

var decode_buf: [5]u8 = undefined;
const decoded = try std.fmt.hexToBytes(&decode_buf, "48656c6c6f");  // "Hello"
```

### Common Format Specifiers

| Specifier | Type | Example | Output |
|-----------|------|---------|--------|
| `{s}` | String slice | `"text: {s}"` | `text: hello` |
| `{d}` | Decimal integer | `"count: {d}"` | `count: 42` |
| `{x}` | Lowercase hex | `"addr: 0x{x}"` | `addr: 0x2a` |
| `{X}` | Uppercase hex | `"ADDR: 0x{X}"` | `ADDR: 0x2A` |
| `{b}` | Binary | `"bits: {b}"` | `bits: 101010` |
| `{o}` | Octal | `"octal: {o}"` | `octal: 52` |
| `{c}` | Single character | `"char: {c}"` | `char: A` |
| `{e}` | Scientific notation | `"val: {e}"` | `val: 1.5e+02` |
| `{}` | Default formatting | `"value: {}"` | (type-dependent) |
| `{any}` | Debug format | `"debug: {any}"` | (detailed debug output) |

### ⚠️ Critical: Buffer Sizing
```zig
// TOO SMALL - Will return error.NoSpaceLeft!
var tiny: [5]u8 = undefined;
const result = std.fmt.bufPrint(&tiny, "Hello, World!", .{}); // ERROR!

// Correct - Always size buffer larger than needed
var buffer: [100]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "Hello, World!", .{}); // ✅

// Alternative - Use allocPrint when size is unknown
const result = try std.fmt.allocPrint(allocator, "Hello, World!", .{});
```

---

## Overview

`std.fmt` is Zig's string formatting and parsing namespace, providing compile-time format string validation, type-safe formatting, and robust parsing utilities. It's designed to be both safe and efficient, with all format strings validated at compile time.

**Key Characteristics:**
- **Compile-time format validation**: Format strings must be `comptime` known, catching errors at build time
- **Type-safe**: Format specifiers are automatically matched against argument types
- **Zero-allocation options**: `bufPrint` works with stack buffers, no allocator required
- **Rich specifier set**: Supports decimal, hex, binary, octal, scientific notation, and more
- **Bidirectional**: Both formatting (to strings) and parsing (from strings)
- **UTF-8 aware**: Properly handles unicode strings

**When to use std.fmt:**
- Converting numbers to strings for display or logging
- Parsing user input (command-line args, config files, network protocols)
- Formatting error messages and debug output
- Encoding/decoding hexadecimal data
- Any scenario requiring printf-style formatting without C dependencies

## Format Specifiers Reference

### Basic Specifiers

**`{s}` - String Slice**
- Works with: `[]const u8`, `[]u8`, string literals
- Output: Raw string content
```zig
std.fmt.bufPrint(&buf, "Name: {s}", .{"Alice"});  // "Name: Alice"
```

**`{d}` - Decimal Integer**
- Works with: All integer types (signed/unsigned)
- Output: Base-10 representation
```zig
std.fmt.bufPrint(&buf, "Count: {d}", .{42});      // "Count: 42"
std.fmt.bufPrint(&buf, "Neg: {d}", .{-100});      // "Neg: -100"
```

**`{x}` - Lowercase Hexadecimal**
- Works with: Integer types
- Output: Base-16 lowercase (no 0x prefix)
```zig
std.fmt.bufPrint(&buf, "Hex: {x}", .{255});       // "Hex: ff"
```

**`{X}` - Uppercase Hexadecimal**
- Works with: Integer types
- Output: Base-16 uppercase (no 0x prefix)
```zig
std.fmt.bufPrint(&buf, "HEX: {X}", .{255});       // "HEX: FF"
```

**`{b}` - Binary**
- Works with: Integer types
- Output: Base-2 representation (no 0b prefix)
```zig
std.fmt.bufPrint(&buf, "Binary: {b}", .{5});      // "Binary: 101"
```

**`{o}` - Octal**
- Works with: Integer types
- Output: Base-8 representation (no 0o prefix)
```zig
std.fmt.bufPrint(&buf, "Octal: {o}", .{8});       // "Octal: 10"
```

**`{c}` - Character**
- Works with: `u8`, `u21` (unicode codepoint)
- Output: Single character
```zig
std.fmt.bufPrint(&buf, "Char: {c}", .{65});       // "Char: A"
```

**`{e}` - Scientific Notation**
- Works with: Float types (`f16`, `f32`, `f64`, `f128`)
- Output: Exponential format
```zig
std.fmt.bufPrint(&buf, "Sci: {e}", .{1500.0});    // "Sci: 1.5e+03"
```

**`{}` - Default Format**
- Works with: Most types
- Output: Type-appropriate default representation
```zig
std.fmt.bufPrint(&buf, "Value: {}", .{42});       // "Value: 42"
std.fmt.bufPrint(&buf, "Float: {}", .{3.14});     // "Float: 3.14"
```

**`{any}` - Debug Format**
- Works with: All types
- Output: Detailed debug representation (shows struct fields, array contents, etc.)
```zig
const Point = struct { x: i32, y: i32 };
const p = Point{ .x = 10, .y = 20 };
std.fmt.bufPrint(&buf, "Point: {any}", .{p});     // "Point: Point{ .x = 10, .y = 20 }"
```

### Format Options

**Width and Padding**
```zig
std.fmt.bufPrint(&buf, "|{d:5}|", .{42});         // "|   42|" (right-aligned, width 5)
std.fmt.bufPrint(&buf, "|{s:10}|", .{"hi"});      // "|hi        |" (left-aligned for strings)
```

**Precision for Floats**
```zig
std.fmt.bufPrint(&buf, "{d:.2}", .{3.14159});     // "3.14" (2 decimal places)
std.fmt.bufPrint(&buf, "{d:.4}", .{2.5});         // "2.5000" (pad to 4 places)
```

**Fill Character**
```zig
std.fmt.bufPrint(&buf, "{d:0>5}", .{42});         // "00042" (zero-padded)
```

------

## Formatting Functions

### `pub fn bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype) BufPrintError![]u8`

Formats into a stack-allocated buffer. Most common formatting function when output size is predictable.

**Parameters:**
- `buf` - Destination buffer (must be large enough)
- `fmt` - Compile-time format string
- `args` - Tuple of arguments matching format specifiers

**Returns:** Slice of `buf` containing formatted data (NOT null-terminated)

**Errors:** `error.NoSpaceLeft` if buffer is too small

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var buffer: [100]u8 = undefined;

    const msg = try std.fmt.bufPrint(&buffer, "User {s} has {d} points", .{"Alice", 42});

    std.debug.print("Result: {s}\n", .{msg});
    std.debug.print("Length: {d} bytes\n", .{msg.len});
}
```

------

### `pub fn allocPrint(allocator: Allocator, comptime fmt: []const u8, args: anytype) Allocator.Error![]u8`

Formats into heap-allocated memory. Use when output size is unknown or potentially large.

**Parameters:**
- `allocator` - Allocator for memory allocation
- `fmt` - Compile-time format string
- `args` - Tuple of arguments matching format specifiers

**Returns:** Owned slice containing formatted data (caller must free)

**Errors:** `error.OutOfMemory` if allocation fails

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const msg = try std.fmt.allocPrint(allocator, "Dynamic: {s} = {d}", .{"answer", 42});
    defer allocator.free(msg);

    std.debug.print("{s}\n", .{msg});
}
```

------

### `pub fn comptimePrint(comptime fmt: []const u8, args: anytype) *const [count(fmt, args):0]u8`

Formats entirely at compile time. Returns a null-terminated string literal.

**Parameters:**
- `fmt` - Compile-time format string
- `args` - Compile-time known arguments

**Returns:** Pointer to compile-time string (null-terminated)

**Use case:** Generating string constants at compile time

**Example:**
```zig
const version = std.fmt.comptimePrint("v{d}.{d}.{d}", .{1, 2, 3}); // "v1.2.3"
// version is a compile-time constant, zero runtime cost
```

------

### `pub fn count(comptime fmt: []const u8, args: anytype) usize`

Calculates how many bytes are needed to format the given arguments. Useful for pre-sizing buffers.

**Example:**
```zig
const needed = comptime std.fmt.count("Value: {d}", .{12345}); // Returns 12
var buffer: [needed]u8 = undefined;
const result = std.fmt.bufPrint(&buffer, "Value: {d}", .{12345}) catch unreachable;
```

------

## Parsing Functions

### `pub fn parseInt(comptime T: type, buf: []const u8, base: u8) ParseIntError!T`

Parses a string as a signed or unsigned integer in any base (2-36).

**Parameters:**
- `T` - Target integer type (e.g., `i32`, `u64`)
- `buf` - String to parse
- `base` - Number base (2 for binary, 10 for decimal, 16 for hex, etc.)

**Errors:**
- `error.Overflow` - Number too large for type `T`
- `error.InvalidCharacter` - Non-digit character found

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const dec = try std.fmt.parseInt(i32, "42", 10);
    std.debug.print("Decimal: {d}\n", .{dec}); // 42

    const hex = try std.fmt.parseInt(u32, "DEADBEEF", 16);
    std.debug.print("Hex: 0x{X}\n", .{hex}); // 0xDEADBEEF

    const bin = try std.fmt.parseInt(u8, "11010", 2);
    std.debug.print("Binary: {d}\n", .{bin}); // 26

    // Leading +/- signs are allowed
    const neg = try std.fmt.parseInt(i32, "-123", 10);
    std.debug.print("Negative: {d}\n", .{neg}); // -123
}
```

------

### `pub fn parseUnsigned(comptime T: type, buf: []const u8, base: u8) ParseIntError!T`

Parses a string as an unsigned integer. Rejects negative signs.

**Example:**
```zig
const val = try std.fmt.parseUnsigned(u32, "12345", 10); // ✅ 12345
const bad = std.fmt.parseUnsigned(u32, "-100", 10);      // ❌ error.InvalidCharacter
```

------

### `pub fn parseFloat(comptime T: type, s: []const u8) ParseFloatError!T`

Parses a string as a floating-point number.

**Parameters:**
- `T` - Target float type (`f16`, `f32`, `f64`, `f128`)
- `s` - String to parse

**Supported formats:**
- Decimal: `"3.14"`, `"-2.5"`
- Scientific: `"1.5e10"`, `"6.022e-23"`
- Special values: `"inf"`, `"-inf"`, `"nan"`

**Errors:**
- `error.InvalidCharacter` - Malformed number

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const pi = try std.fmt.parseFloat(f64, "3.14159");
    std.debug.print("Pi: {d}\n", .{pi});

    const sci = try std.fmt.parseFloat(f32, "6.022e23");
    std.debug.print("Avogadro: {e}\n", .{sci});

    const inf = try std.fmt.parseFloat(f64, "inf");
    std.debug.print("Infinity: {d}\n", .{inf});
}
```

------

## Hex Utilities

### `pub fn bytesToHex(input: anytype, case: Case) [input.len * 2]u8`

Encodes bytes as hexadecimal string. Returns fixed-size array (2 hex digits per byte).

**Parameters:**
- `input` - Byte array or slice
- `case` - `.lower` or `.upper`

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const bytes = "Hi";
    const hex_lower = std.fmt.bytesToHex(bytes, .lower);
    const hex_upper = std.fmt.bytesToHex(bytes, .upper);

    std.debug.print("Bytes: {s}\n", .{bytes});
    std.debug.print("Hex (lower): {s}\n", .{hex_lower}); // "4869"
    std.debug.print("Hex (upper): {s}\n", .{hex_upper}); // "4869"
}
```

------

### `pub fn hexToBytes(out: []u8, input: []const u8) ![]u8`

Decodes hexadecimal string to bytes.

**Parameters:**
- `out` - Output buffer (must be at least `input.len / 2` bytes)
- `input` - Hex string to decode (even length required)

**Returns:** Slice of `out` containing decoded bytes

**Errors:** `error.InvalidCharacter` if non-hex character found

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var buffer: [10]u8 = undefined;
    const decoded = try std.fmt.hexToBytes(&buffer, "48656C6C6F");
    std.debug.print("Decoded: {s}\n", .{decoded}); // "Hello"
}
```

------

## Utility Functions

### `pub fn charToDigit(c: u8, base: u8) error{InvalidCharacter}!u8`

Converts a character to its digit value in a given base.

**Example:**
```zig
const val = try std.fmt.charToDigit('F', 16); // 15
const dec = try std.fmt.charToDigit('7', 10); // 7
```

------

### `pub fn digitToChar(digit: u8, case: Case) u8`

Converts a digit (0-35) to its character representation.

**Example:**
```zig
const c = std.fmt.digitToChar(15, .lower); // 'f'
const C = std.fmt.digitToChar(15, .upper); // 'F'
```

------

## Usage Patterns

### Pattern 1: Command-Line Argument Parsing

```zig
const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: program <number>\n", .{});
        return;
    }

    const num = try std.fmt.parseInt(i32, args[1], 10);
    std.debug.print("You entered: {d}\n", .{num});
    std.debug.print("Doubled: {d}\n", .{num * 2});
}
```

### Pattern 2: Building Formatted Strings Incrementally

```zig
const std = @import("std");

pub fn buildReport(allocator: std.mem.Allocator) ![]u8 {
    const name = "Alice";
    const score = 95;
    const grade = 'A';

    return std.fmt.allocPrint(allocator,
        \\--- Student Report ---
        \\Name:  {s}
        \\Score: {d}
        \\Grade: {c}
        \\Status: {s}
    , .{name, score, grade, if (score >= 90) "Excellent" else "Good"});
}
```

### Pattern 3: Protocol Encoding (Hex + Binary)

```zig
const std = @import("std");

pub fn encodePacket(buf: []u8, id: u32, payload: []const u8) ![]u8 {
    // Encode as: <4-byte hex ID><payload>
    const hex_id = std.fmt.bytesToHex(std.mem.asBytes(&id), .lower);

    var fbs = std.io.fixedBufferStream(buf);
    const writer = fbs.writer();

    try writer.writeAll(&hex_id);
    try writer.writeAll(payload);

    return fbs.getWritten();
}
```

### Pattern 4: Safe Buffer Formatting with Size Check

```zig
const std = @import("std");

pub fn formatSafe(buf: []u8, name: []const u8, value: i32) ![]u8 {
    // Check if buffer is large enough before formatting
    const needed = std.fmt.count("Name: {s}, Value: {d}", .{name, value});

    if (needed > buf.len) {
        return error.BufferTooSmall;
    }

    return std.fmt.bufPrint(buf, "Name: {s}, Value: {d}", .{name, value});
}
```

------

## Error Sets

### `BufPrintError`
- `error.NoSpaceLeft` - Buffer too small for formatted output

### `ParseIntError`
- `error.Overflow` - Number too large for target type
- `error.InvalidCharacter` - Non-digit character in input

### `ParseFloatError`
- `error.InvalidCharacter` - Malformed floating-point number

------

## Debug Checklist

✅ **Format string is `comptime` known** - Cannot use runtime strings as format strings

✅ **Buffer is large enough** - For `bufPrint`, ensure buffer can hold the output (use `count()` to pre-calculate)

✅ **Number of arguments matches specifiers** - `"Value: {d}"` needs exactly 1 argument

✅ **Argument types match specifiers** - `{s}` needs string, `{d}` needs integer, etc.

✅ **Free allocated strings** - `allocPrint` returns owned memory - must call `allocator.free()`

✅ **parseInt base is valid** - Base must be 2-36

✅ **Hex strings have even length** - `hexToBytes` requires pairs of hex digits

✅ **Output buffer sized correctly** - For `hexToBytes`, output buffer needs `input.len / 2` bytes

✅ **Handle overflow errors** - parseInt can overflow - handle `error.Overflow` explicitly

✅ **Watch for truncation** - `bufPrint` returns a slice - check the length if you need to know

------

## Performance Tips

1. **Prefer `bufPrint` over `allocPrint`** - Stack allocation is faster and doesn't fragment the heap. Use `allocPrint` only when size is truly unknown.

2. **Pre-calculate buffer sizes** - Use `std.fmt.count()` to determine exact buffer size needed:
   ```zig
   const size = std.fmt.count("Value: {d}", .{12345});
   var buffer: [size]u8 = undefined; // Exactly right-sized
   ```

3. **Reuse buffers** - Don't allocate a new buffer for each formatting operation:
   ```zig
   var buffer: [1024]u8 = undefined;
   for (items) |item| {
       const msg = try std.fmt.bufPrint(&buffer, "Item: {d}", .{item});
       // Use msg...
   }
   ```

4. **Use `comptimePrint` for constants** - Zero runtime cost for compile-time strings:
   ```zig
   const version = std.fmt.comptimePrint("v{d}.{d}", .{1, 0}); // Free at runtime
   ```

5. **Avoid `{any}` in production** - Debug formatting is slower and verbose. Use specific specifiers (`{d}`, `{s}`, etc.) for production code.

6. **Batch parsing operations** - If parsing many numbers, consider parsing in bulk rather than one-by-one to improve cache locality.

7. **Watch base conversion cost** - Binary and hex conversions (`{b}`, `{x}`) are cheaper than decimal (`{d}`) for powers-of-2 integers.

------

## Types and Constants

### User-Facing Types

**`Case` (enum)**
```zig
pub const Case = enum { lower, upper };
```
Used with `bytesToHex` and `digitToChar` to specify letter case.
- `.lower` - Lowercase hex digits (a-f)
- `.upper` - Uppercase hex digits (A-F)

**Example:**
```zig
const hex = std.fmt.bytesToHex("Hi", .lower); // "4869"
const HEX = std.fmt.bytesToHex("Hi", .upper); // "4869"
```

------

**`Alignment` (enum)**
```zig
pub const Alignment = enum { left, center, right };
```
Controls text alignment within formatted output width.
- `.left` - Align to left, pad right
- `.center` - Center text, pad both sides
- `.right` - Align to right, pad left (default for numbers)

**Example:**
```zig
std.fmt.bufPrint(&buf, "|{s:<10}|", .{"hi"});  // "|hi        |" (left)
std.fmt.bufPrint(&buf, "|{s:^10}|", .{"hi"});  // "|    hi    |" (center)
std.fmt.bufPrint(&buf, "|{d:>5}|", .{42});     // "|   42|" (right)
```

------

**`Options` (struct)**
```zig
pub const Options = struct {
    precision: ?usize = null,
    width: ?usize = null,
    alignment: Alignment = .right,
    fill: u8 = ' ',
};
```
Format options for controlling output appearance. Typically constructed via format specifier syntax (e.g., `{d:5.2}`) rather than directly.

**Fields:**
- `precision` - Number of decimal places for floats
- `width` - Minimum output width (pads if needed)
- `alignment` - Text alignment within width
- `fill` - Character used for padding (default: space)

------

**`Number` (struct)**
```zig
pub const Number = struct {
    mode: Mode = .decimal,
    case: Case = .lower,
    precision: ?usize = null,
    width: ?usize = null,
    alignment: Alignment = .right,
    fill: u8 = ' ',
};
```
Extended formatting options for numeric output. Includes number base/mode.

**Nested Types:**
- `Mode` - enum: `.decimal`, `.binary`, `.octal`, `.hexadecimal`, `.scientific`

------

### Internal Types (Advanced Use)

**`Parser` (struct)**
```zig
pub const Parser = struct {
    bytes: []const u8,
    i: usize,
};
```
Stream-based parser for format strings. Used internally by `std.fmt` but can be used to implement custom formatters.

**Methods:**
- `char() ?u8` - Get next character
- `maybe(byte: u8) bool` - Try to consume specific byte
- `number() ?usize` - Parse number from current position
- `peek(i: usize) ?u8` - Look ahead without consuming
- `specifier() !Specifier` - Parse format specifier
- `until(delimiter: u8) []const u8` - Read until delimiter

------

**`Specifier` (union)**
```zig
pub const Specifier = union(enum) {
    none,
    number: usize,
    named: []const u8,
};
```
Represents a parsed format argument specifier. Used internally by the parser.

**Variants:**
- `none` - Anonymous placeholder `{}`
- `number` - Positional argument `{0}`, `{1}`
- `named` - Named argument `{name}` (not commonly used)

------

**`Placeholder` (struct)**
```zig
pub const Placeholder = struct {
    specifier: Specifier,
    options: Options,
};
```
Complete parsed format placeholder (combines specifier + options).

------

**`ArgState` (struct)**
Internal state tracking for format argument consumption.

------

**`ArgSetType` (type function)**
Internal helper for argument set type construction.

------

**`Alt` (struct)**
Internal type for alternative formatting modes.

------

### Constants

**`default_max_depth: usize`**
Maximum recursion depth for debug formatting (`{any}`). Prevents infinite loops when printing recursive structures.

------

**`hex_charset: [16]u8`**
Lowercase hexadecimal character set: `"0123456789abcdef"`

------

**`float` (namespace)**
Internal floating-point formatting utilities.

------

## See Also

- **std.mem** - Memory utilities (slicing, comparison, searching)
- **std.Io.Writer** - Streaming formatted output
- **std.debug.print** - Quick debug printing (uses fmt internally)
- **std.json** - JSON formatting and parsing
- **std.log** - Structured logging with formatting
