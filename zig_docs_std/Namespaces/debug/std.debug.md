# std.debug

📚 **[See Comprehensive Examples & Tests](../../Examples/debug_tests.zig)** - Complete runnable code demonstrating all debug features

## Quick Start

### Most Common Patterns

**Basic Debug Printing**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello from debug! Value: {d}\n", .{42});
}
```

**Runtime Assertions**
```zig
const std = @import("std");

pub fn divide(a: i32, b: i32) i32 {
    std.debug.assert(b != 0); // Panics in Debug/ReleaseSafe modes
    return @divExact(a, b);
}
```

**Printing Stack Traces**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.dumpCurrentStackTrace(.{});
}
```

**Hex Dump for Binary Data**
```zig
const std = @import("std");

pub fn main() void {
    const data = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE };
    std.debug.dumpHex(&data);
}
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Print to stderr | `print()` | `std.debug.print("value: {}\n", .{x})` |
| Runtime assertion | `assert()` | `std.debug.assert(ptr != null)` |
| Print stack trace | `dumpCurrentStackTrace()` | `std.debug.dumpCurrentStackTrace(.{})` |
| Formatted panic | `panic()` | `std.debug.panic("Error: {s}", .{msg})` |
| Hex dump | `dumpHex()` | `std.debug.dumpHex(bytes)` |
| Check alignment | `assertAligned()` | `std.debug.assertAligned(ptr, 16)` |

### ⚠️ Critical: Debug vs Release Behavior

```zig
// In Debug and ReleaseSafe modes:
std.debug.assert(x > 0); // ✅ Panics if x <= 0

// In ReleaseFast and ReleaseSmall modes:
std.debug.assert(x > 0); // ❌ NO-OP! Assertion is removed!

// ALWAYS enforced (use for critical invariants):
if (x <= 0) @panic("x must be positive"); // ✅ Always checked
```

**Key point:** `std.debug.assert()` is compiled out in optimized builds. Use `@panic()` or error returns for production-critical checks.

---

## Overview

`std.debug` provides debugging utilities including formatted printing to stderr, runtime assertions, stack trace capture and printing, panic handlers, and low-level debug information access. It is the primary namespace for development-time diagnostics in Zig.

**Key Characteristics:**
- **Build-mode aware** - Many functions (like `assert`) are no-ops in optimized builds
- **Stderr output** - All output goes to stderr, leaving stdout free for program output
- **Stack unwinding** - Platform-specific stack trace capture and symbolication
- **No allocation by default** - Most functions ignore I/O errors and use internal buffers
- **Thread-safe debug info** - Debug information loading is synchronized for multi-threaded use

**When to use std.debug:**
- Quick debugging during development (print statements, assertions)
- Stack trace capture in error handlers and crash reporters
- Implementing custom panic handlers or debug output
- Inspecting binary data with hex dumps
- Validating invariants that should only be checked in debug builds

**Related namespaces:**
- `std.log` - Structured logging with compile-time filtering (preferred for production)
- `std.testing` - Test-specific assertions with detailed failure messages
- `std.builtin.StackTrace` - The stack trace type used throughout the standard library

---

## Core Types

### `SourceLocation`

Represents a resolved runtime source location for an instruction pointer.

**Fields:**
- `line: u64` - Line number (1-indexed)
- `column: u64` - Column number (1-indexed)
- `file_name: []const u8` - Source file path/name

**Example:**
```zig
const std = @import("std");

pub fn printResolvedLocation(symbol: std.debug.Symbol) void {
    if (symbol.source_location) |loc| {
        std.debug.print("{s}:{d}:{d}\n", .{
            loc.file_name,
            loc.line,
            loc.column,
        });
    }
}
```

------

### `Symbol`

Debug information about a specific address, returned by `getSymbol()`.

**Fields:**
- `name: ?[]const u8` - Function or symbol name
- `compile_unit_name: ?[]const u8` - Source/object context if available
- `source_location: ?SourceLocation` - Source location if available

**Example:**
```zig
const std = @import("std");

pub fn example(gpa: std.mem.Allocator, io: std.Io) !void {
    const addr = @intFromPtr(&example);
    const self_info = try std.debug.getSelfDebugInfo();
    const symbol = try self_info.getSymbol(gpa, io, addr);
    std.debug.print("Symbol: {s}\n", .{symbol.name orelse "<unknown>"});
}
```

------

### `StackTrace`

A captured stack trace, containing an array of instruction pointers.

**Fields:**
- `index: usize` - Number of frames captured
- `instruction_addresses: []usize` - Array of return addresses

**Note:** This type is defined in `std.builtin.StackTrace` but extensively used by `std.debug`.

------

### `StackUnwindOptions`

Options for stack unwinding operations.

**Fields:**
- `first_address: ?usize = null` - Skip frames before this address
- `context: ?CpuContextPtr = null` - Unwind from specific CPU context (for signal handlers)
- `allow_unsafe_unwind: bool = false` - Use potentially-crashy unwinding strategies as last resort

**Example:**
```zig
const options = std.debug.StackUnwindOptions{
    .first_address = @returnAddress(),
    .allow_unsafe_unwind = false,
};
std.debug.dumpCurrentStackTrace(options);
```

------

## Functions

### Printing Functions

#### `pub fn print(comptime fmt: []const u8, args: anytype) void`

Writes formatted output to stderr, ignoring any I/O errors. This is the most commonly used debug function.

**Parameters:**
- `fmt` - Compile-time format string (same syntax as `std.fmt`)
- `args` - Tuple of arguments matching format specifiers

**Thread Safety:** Acquires stderr lock automatically.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const x = 42;
    const name = "Alice";

    std.debug.print("User: {s}, Score: {d}\n", .{ name, x });
    std.debug.print("Hex: 0x{x:0>4}\n", .{x});
    std.debug.print("Binary: 0b{b}\n", .{x});
}
```

**Output:**
```
User: Alice, Score: 42
Hex: 0x002a
Binary: 0b101010
```

------

### Assertion Functions

#### `pub fn assert(ok: bool) void`

Invokes detectable illegal behavior when `ok` is `false` in Debug and ReleaseSafe modes. Compiled to a no-op in ReleaseFast and ReleaseSmall.

**Parameters:**
- `ok` - Condition that must be true

**Build Mode Behavior:**
- **Debug/ReleaseSafe:** Panics if `ok == false`
- **ReleaseFast/ReleaseSmall:** No-op (optimized away)

**Example:**
```zig
const std = @import("std");

pub fn find(items: []const i32, target: i32) ?usize {
    std.debug.assert(items.len > 0); // Catch empty array during development

    for (items, 0..) |item, i| {
        if (item == target) return i;
    }
    return null;
}

pub fn main() void {
    const items = [_]i32{ 1, 2, 3 };
    _ = find(&items, 2);

    // This would panic in debug builds:
    // _ = find(&[_]i32{}, 2);
}
```

------

#### `pub fn assertAligned(ptr: anytype, comptime alignment: std.mem.Alignment) void`

Verifies that a pointer is aligned to the specified byte boundary. Panics in debug builds if misaligned.

**Parameters:**
- `ptr` - Pointer to check
- `alignment` - Required alignment as `std.mem.Alignment` enum value

**Example:**
```zig
const std = @import("std");

pub fn processAligned(data: []align(16) u8) void {
    // 16 = 2^4, so use @enumFromInt(4)
    std.debug.assertAligned(data.ptr, @as(std.mem.Alignment, @enumFromInt(4)));
    // Process data assuming 16-byte alignment...
}

pub fn main() void {
    var buffer: [64]u8 align(16) = undefined;
    processAligned(&buffer);
}
```

------

#### `pub fn assertReadable(slice: []const volatile u8) void`

Verifies that a memory region is readable by performing a no-op read. Useful for detecting invalid pointers or unmapped memory.

**Parameters:**
- `slice` - Memory region to validate

**Example:**
```zig
const std = @import("std");

pub fn safeRead(ptr: [*]const u8, len: usize) void {
    const slice = ptr[0..len];
    std.debug.assertReadable(@volatileCast(slice));
    std.debug.print("Data is readable: {d} bytes\n", .{len});
}
```

------

### Stack Trace Functions

#### `pub noinline fn captureCurrentStackTrace(options: StackUnwindOptions, addr_buf: []usize) StackTrace`

Captures the current call stack into a user-provided buffer. The returned `StackTrace` is only valid while `addr_buf` remains alive.

**Parameters:**
- `options` - Unwinding options (typically use `.first_address = @returnAddress()` to skip this frame)
- `addr_buf` - Buffer to store instruction pointers (typically 32-128 elements)

**Returns:** `StackTrace` containing captured frames

**Example:**
```zig
const std = @import("std");

pub fn captureTrace() std.builtin.StackTrace {
    var addrs: [32]usize = undefined;
    const trace = std.debug.captureCurrentStackTrace(.{
        .first_address = @returnAddress(),
    }, &addrs);
    return trace;
}

pub fn main() void {
    const trace = captureTrace();
    std.debug.print("Captured {d} stack frames\n", .{trace.index});
}
```

------

#### `pub noinline fn writeCurrentStackTrace(options: StackUnwindOptions, t: Io.Terminal) Writer.Error!void`

Writes the current stack trace to a terminal, with source locations and symbolication.

**Parameters:**
- `options` - Unwinding options
- `t` - Terminal to write to (typically stderr)

**Errors:** Returns any writer errors

**Example:**
```zig
const std = @import("std");

pub fn logError(msg: []const u8) !void {
    const stderr = std.Io.getStdErr();
    const term = stderr.terminal(std.heap.page_allocator);

    try term.setColor(.red);
    try term.writer.writeAll("ERROR: ");
    try term.reset();
    try term.writer.print("{s}\n", .{msg});

    try std.debug.writeCurrentStackTrace(.{}, term);
}

pub fn main() !void {
    try logError("Something went wrong");
}
```

------

#### `pub fn dumpCurrentStackTrace(options: StackUnwindOptions) void`

Convenience wrapper around `writeCurrentStackTrace` that writes to stderr and ignores errors. Most commonly used form.

**Parameters:**
- `options` - Unwinding options (typically `.{}` or with `.first_address`)

**Example:**
```zig
const std = @import("std");

pub fn debugCheckpoint(label: []const u8) void {
    std.debug.print("\n=== DEBUG: {s} ===\n", .{label});
    std.debug.dumpCurrentStackTrace(.{});
    std.debug.print("==================\n\n", .{});
}

fn innerFunction() void {
    debugCheckpoint("Inner function reached");
}

fn outerFunction() void {
    innerFunction();
}

pub fn main() void {
    outerFunction();
}
```

------

#### `pub fn dumpStackTrace(st: *const StackTrace) void`

Prints a previously captured stack trace. Ignores write errors.

**Parameters:**
- `st` - Pointer to captured stack trace

**Example:**
```zig
const std = @import("std");

var saved_trace: ?std.builtin.StackTrace = null;
var trace_addrs: [32]usize = undefined;

pub fn saveTrace() void {
    saved_trace = std.debug.captureCurrentStackTrace(.{}, &trace_addrs);
}

pub fn printSavedTrace() void {
    if (saved_trace) |*trace| {
        std.debug.print("Saved stack trace:\n", .{});
        std.debug.dumpStackTrace(trace);
    }
}

pub fn main() void {
    saveTrace();
    std.debug.print("Doing other work...\n", .{});
    printSavedTrace();
}
```

------

### Panic Functions

#### `pub fn panic(comptime format: []const u8, args: anytype) noreturn`

Triggers a panic with a formatted message. Equivalent to `@panic` but with string formatting.

**Parameters:**
- `format` - Compile-time format string
- `args` - Format arguments

**Example:**
```zig
const std = @import("std");

pub fn safeDivide(a: i32, b: i32) i32 {
    if (b == 0) {
        std.debug.panic("Division by zero: {d} / {d}", .{ a, b });
    }
    return @divExact(a, b);
}

pub fn main() void {
    _ = safeDivide(10, 2); // OK
    // _ = safeDivide(10, 0); // Would panic
}
```

------

#### `pub fn panicExtra(ret_addr: ?usize, comptime format: []const u8, args: anytype) noreturn`

Like `panic()` but allows specifying a custom return address for the stack trace.

**Parameters:**
- `ret_addr` - Return address to use as first frame (or null for caller)
- `format` - Format string
- `args` - Format arguments

**Example:**
```zig
const std = @import("std");

pub fn validateInput(value: i32) void {
    if (value < 0) {
        // Stack trace will start from caller, not this function
        std.debug.panicExtra(@returnAddress(), "Invalid value: {d}", .{value});
    }
}
```

------

#### `pub fn defaultPanic(msg: []const u8, first_trace_addr: ?usize) noreturn`

The default panic implementation used by Zig. Dumps stack trace to stderr and aborts.

**Parameters:**
- `msg` - Panic message
- `first_trace_addr` - Starting address for stack trace

**Note:** You can override the panic handler by defining `pub fn panic()` in the root source file.

------

### Hex Dump Functions

#### `pub fn dumpHex(bytes: []const u8) void`

Prints a hexadecimal dump of binary data to stderr, ignoring any errors. Useful for inspecting binary protocols, file formats, or memory contents.

**Parameters:**
- `bytes` - Data to dump

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const packet = [_]u8{
        0x00, 0x01, 0x02, 0x03,
        0xDE, 0xAD, 0xBE, 0xEF,
        0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
    };

    std.debug.print("Packet dump:\n", .{});
    std.debug.dumpHex(&packet);
}
```

**Output:**
```
Packet dump:
00 01 02 03 de ad be ef 48 65 6c 6c 6f
```

------

#### `pub fn dumpHexFallible(t: Io.Terminal, bytes: []const u8) !void`

Fallible version of `dumpHex()` that returns errors instead of ignoring them.

**Parameters:**
- `t` - Terminal to write to
- `bytes` - Data to dump

**Example:**
```zig
const std = @import("std");

pub fn logPacket(data: []const u8) !void {
    const stderr = std.Io.getStdErr();
    const term = stderr.terminal(std.heap.page_allocator);

    try term.writer.writeAll("Packet data:\n");
    try std.debug.dumpHexFallible(term, data);
}
```

------

### Debug Information Functions

#### `pub inline fn getSelfDebugInfo() !*SelfInfo`

Returns debug information for the current process. Loads debug symbols from the executable or shared libraries.

**Returns:** Pointer to static debug info (lives for program duration)

**Errors:** `SelfInfoError` if debug info unavailable or corrupted

**Example:**
```zig
const std = @import("std");

pub fn printCurrentFunction(gpa: std.mem.Allocator, io: std.Io) !void {
    const addr = @returnAddress();
    const debug_info = try std.debug.getSelfDebugInfo();
    const symbol = try debug_info.getSymbol(gpa, io, addr);

    std.debug.print("Current function: {s}\n", .{symbol.name orelse "<unknown>"});
    if (symbol.source_location) |loc| {
        std.debug.print("  at {s}:{d}\n", .{ loc.file_name, loc.line });
    }
}
```

------

#### `pub fn getDebugInfoAllocator() Allocator`

Returns a thread-safe allocator suitable for loading debug information. Used internally by stack trace functions.

**Returns:** Thread-safe allocator

**Note:** This allocator is optimized for debug info loading and may not be suitable for general use.

------

### Segfault Handling Functions

#### `pub fn attachSegfaultHandler() void`

Installs a signal handler that prints stack traces when segmentation faults or other crashes occur.

**Signals Handled:**
- `SIGSEGV` - Segmentation fault
- `SIGILL` - Illegal instruction
- `SIGBUS` - Bus error
- `SIGFPE` - Floating point exception

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.attachSegfaultHandler();

    // Now crashes will print a stack trace
    std.debug.print("Segfault handler installed\n", .{});

    // Normal program execution...
}
```

------

#### `pub fn maybeEnableSegfaultHandler() void`

Conditionally enables the segfault handler based on `default_enable_segfault_handler` constant.

**Note:** This is called automatically by the Zig runtime in debug builds.

------

### Utility Functions

#### `pub inline fn inValgrind() bool`

Detects whether the program is running under the Valgrind memory checker.

**Returns:** `true` if running in Valgrind, `false` otherwise

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    if (std.debug.inValgrind()) {
        std.debug.print("Running under Valgrind\n", .{});
    } else {
        std.debug.print("Running natively\n", .{});
    }
}
```

------

#### `pub fn lockStderr(buffer: []u8) Io.LockedStderr`

Acquires exclusive access to stderr with a temporary buffer. Useful for atomic multi-line output.

**Parameters:**
- `buffer` - Temporary buffer for buffered writes

**Returns:** Locked stderr handle (call `unlockStderr()` when done)

**Note:** In 0.16+, you must call `unlockStderr()` to release the lock (not a method on the handle).

**Example:**
```zig
const std = @import("std");

pub fn atomicPrint() void {
    var buffer: [256]u8 = undefined;
    const locked = std.debug.lockStderr(&buffer);
    defer std.debug.unlockStderr();

    // These writes are atomic (no interleaving from other threads)
    const term = locked.terminal();
    const writer = term.writer; // Note: writer is a field, not a method
    writer.writeAll("Line 1\n") catch {};
    writer.writeAll("Line 2\n") catch {};
    writer.writeAll("Line 3\n") catch {};
}
```

------

#### `pub inline fn stripInstructionPtrAuthCode(ptr: usize) usize`

Removes pointer authentication codes from instruction pointers on platforms that use them (e.g., ARM64 with PAC).

**Parameters:**
- `ptr` - Instruction pointer

**Returns:** Pointer with authentication code stripped

**Note:** This is handled automatically by stack unwinding code.

------

## Usage Patterns

### Pattern 1: Debug Logging During Development

```zig
const std = @import("std");

pub fn processData(data: []const u8) !void {
    std.debug.print("Processing {d} bytes\n", .{data.len});

    for (data, 0..) |byte, i| {
        if (byte == 0) {
            std.debug.print("Found null byte at index {d}\n", .{i});
        }
    }

    std.debug.print("Processing complete\n", .{});
}

pub fn main() !void {
    const data = "Hello\x00World";
    try processData(data);
}
```

**When to use:** Quick debugging during development. Replace with proper logging for production code.

------

### Pattern 2: Capturing Stack Traces in Error Handlers

```zig
const std = @import("std");

const MyError = error{
    InvalidInput,
    ProcessingFailed,
};

fn riskyOperation(value: i32) MyError!i32 {
    if (value < 0) return error.InvalidInput;
    if (value > 100) return error.ProcessingFailed;
    return value * 2;
}

pub fn main() void {
    const result = riskyOperation(-5) catch |err| {
        std.debug.print("Error occurred: {s}\n", .{@errorName(err)});
        std.debug.print("Stack trace:\n", .{});
        std.debug.dumpCurrentStackTrace(.{});
        return;
    };

    std.debug.print("Result: {d}\n", .{result});
}
```

**Explanation:** Captures context when errors occur. Useful for debugging unexpected error paths.

------

### Pattern 3: Custom Panic Handler

```zig
const std = @import("std");

pub const panic = customPanicHandler;

fn customPanicHandler(msg: []const u8, trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = ret_addr;

    // Custom handling (e.g., log to file, send telemetry, etc.)
    const stderr = std.Io.getStdErr();
    const term = stderr.terminal(std.heap.page_allocator);

    term.setColor(.red) catch {};
    term.writer.print("\n!!! PANIC: {s} !!!\n\n", .{msg}) catch {};
    term.reset() catch {};

    if (trace) |t| {
        std.debug.dumpStackTrace(t);
    } else {
        std.debug.dumpCurrentStackTrace(.{});
    }

    // Could write to log file here...

    std.posix.exit(1);
}

pub fn main() void {
    std.debug.panic("Something went wrong!", .{});
}
```

**Explanation:** Provides custom panic behavior like logging, cleanup, or telemetry before exit.

------

### Pattern 4: Validating Assumptions with Assertions

```zig
const std = @import("std");

pub const LinkedList = struct {
    head: ?*Node = null,
    tail: ?*Node = null,
    len: usize = 0,

    pub const Node = struct {
        data: i32,
        next: ?*Node = null,
    };

    pub fn append(self: *LinkedList, node: *Node) void {
        // Validate invariants
        std.debug.assert(node.next == null);
        std.debug.assert(if (self.head == null) self.tail == null else true);
        std.debug.assert(if (self.len == 0) self.head == null else true);

        if (self.tail) |tail| {
            tail.next = node;
            self.tail = node;
        } else {
            self.head = node;
            self.tail = node;
        }
        self.len += 1;

        // Validate postconditions
        std.debug.assert(self.tail == node);
        std.debug.assert(self.len > 0);
    }
};

pub fn main() void {
    var list = LinkedList{};
    var node = LinkedList.Node{ .data = 42 };
    list.append(&node);
}
```

**Explanation:** Use assertions to validate invariants and catch bugs early during development.

------

### Pattern 5: Inspecting Binary Data

```zig
const std = @import("std");

pub fn parsePacket(data: []const u8) !void {
    if (data.len < 4) return error.PacketTooSmall;

    std.debug.print("Packet header:\n", .{});
    std.debug.dumpHex(data[0..4]);

    const magic = std.mem.readInt(u32, data[0..4], .big);
    if (magic != 0xDEADBEEF) {
        std.debug.print("Invalid magic number: 0x{x}\n", .{magic});
        std.debug.print("Expected: 0xDEADBEEF\n", .{});
        std.debug.print("Full packet:\n", .{});
        std.debug.dumpHex(data);
        return error.InvalidMagic;
    }

    std.debug.print("Valid packet\n", .{});
}

pub fn main() !void {
    const valid = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02 };
    const invalid = [_]u8{ 0xCA, 0xFE, 0xBA, 0xBE, 0x01, 0x02 };

    std.debug.print("=== Parsing valid packet ===\n", .{});
    try parsePacket(&valid);

    std.debug.print("\n=== Parsing invalid packet ===\n", .{});
    parsePacket(&invalid) catch |err| {
        std.debug.print("Caught error: {s}\n", .{@errorName(err)});
    };
}
```

**Explanation:** Hex dumps are invaluable for debugging binary formats, network protocols, or file parsers.

------

## Types and Constants

### User-Facing Types

**`SourceLocation` (struct)**
```zig
pub const SourceLocation = struct {
    line: u64,
    column: u64,
    file_name: []const u8,
};
```
Resolved source location from debug information.

------

**`Symbol` (struct)**
```zig
pub const Symbol = struct {
    name: ?[]const u8,
    compile_unit_name: ?[]const u8,
    source_location: ?SourceLocation,
};
```
Debug symbol information for an address.

------

**`StackUnwindOptions` (struct)**
```zig
pub const StackUnwindOptions = struct {
    first_address: ?usize = null,
    context: ?CpuContextPtr = null,
    allow_unsafe_unwind: bool = false,
};
```
Options for stack trace capture and unwinding.

------

### Advanced Types

**`SelfInfo` (type)**

Platform-specific debug information for the current process. Varies by target:
- **Windows:** PE/COFF + PDB
- **Linux/BSD:** ELF + DWARF
- **macOS:** Mach-O + DWARF

Access via `getSelfDebugInfo()`.

------

**`Dwarf` (struct)**

DWARF debug information parser. See `std.debug.Dwarf` for details.

------

**`ElfFile` (struct)**

ELF binary file parser for debug info extraction.

------

**`MachOFile` (struct)**

Mach-O binary file parser for macOS/iOS debug info.

------

**`Pdb` (struct)**

PDB (Program Database) parser for Windows debug info.

------

### Constants

**`sys_can_stack_trace: bool`**

Whether the current platform supports stack unwinding. When `false`, stack trace functions return empty traces but don't error.

------

**`have_segfault_handling_support: bool`**

Whether the platform supports installing segfault handlers. When `false`, `attachSegfaultHandler()` is a no-op.

------

**`runtime_safety: bool`** ⚠️ Deprecated

Returns the standard library's build mode, not the caller's. Use `std.debug.assert()` behavior directly instead.

------

**`default_enable_segfault_handler: bool`**

Whether segfault handlers are enabled by default. Can be overridden in root module.

------

## Error Sets

### `SelfInfoError`
- `error.InvalidDebugInfo` - Debug information is corrupted or malformed
- `error.MissingDebugInfo` - No debug information available (stripped binary)
- `error.UnsupportedDebugInfo` - Debug info format not supported by this implementation
- `error.ReadFailed` - I/O error reading debug information
- `error.OutOfMemory` - Allocation failed while loading debug info
- `error.Canceled` - Operation was canceled
- `error.Unexpected` - Unexpected system error

------

## Debug Checklist

✅ **Use `std.debug.print()` for temporary debugging** - Remove or convert to proper logging before committing

✅ **`assert()` is compiled out in release builds** - Use `@panic()` or error returns for production checks

✅ **Stack traces require debug info** - Compile with `-g` or equivalent for meaningful traces

✅ **Hex dumps work on any `[]const u8`** - Great for inspecting packets, file headers, or memory

✅ **Custom panic handlers go in root file** - Define `pub const panic = myHandler;` to override default

✅ **Stack trace buffers need sufficient size** - 32-128 frames is typical; adjust based on call depth

✅ **Segfault handlers aren't always available** - Check `have_segfault_handling_support` before relying on them

------

## Performance Tips

1. **Remove debug prints before release** - They're not free even when optimized:
   ```zig
   // Conditionally compile debug code
   if (builtin.mode == .Debug) {
       std.debug.print("Debug info: {}\n", .{value});
   }
   ```

2. **Use `std.log` instead of `std.debug.print` for production** - Provides compile-time filtering:
   ```zig
   // Filtered at compile time in release builds
   std.log.debug("Processing item {}", .{i});
   ```

3. **Batch debug output with `lockStderr`** - Reduces lock contention:
   ```zig
   var buffer: [1024]u8 = undefined;
   const locked = std.debug.lockStderr(&buffer);
   defer std.debug.unlockStderr();
   const term = locked.terminal();
   // Multiple writes here are atomic and buffered
   ```

4. **Don't capture stack traces on hot paths** - Stack unwinding is expensive:
   ```zig
   // BAD: Capturing trace in tight loop
   for (items) |item| {
       std.debug.dumpCurrentStackTrace(.{});
       process(item);
   }

   // GOOD: Only on error paths
   for (items) |item| {
       process(item) catch |err| {
           std.debug.dumpCurrentStackTrace(.{});
           return err;
       };
   }
   ```

5. **Reuse stack trace buffers** - Avoid repeated allocations:
   ```zig
   var trace_buf: [64]usize = undefined;
   for (checkpoints) |cp| {
       const trace = std.debug.captureCurrentStackTrace(.{}, &trace_buf);
       logCheckpoint(cp, trace);
   }
   ```

6. **Use `noinline` sparingly** - `captureCurrentStackTrace` is marked `noinline` to appear in traces, but this prevents optimization

7. **Strip debug info for minimal binaries** - Use `--strip` or `-Doptimize=ReleaseSmall`:
   ```bash
   zig build -Doptimize=ReleaseSmall --strip
   ```

------

## See Also

- **std.log** - Structured logging with compile-time level filtering (preferred over debug.print)
- **std.testing** - Test-specific assertions with detailed failure messages
- **std.builtin.StackTrace** - Stack trace type definition
- **std.Io.Writer** - General-purpose output formatting
- **std.fmt** - String formatting (used by debug.print internally)
- **@panic** - Built-in panic function
- **@src** - Built-in function returning `SourceLocation`
- **@returnAddress** - Built-in function for getting return address
