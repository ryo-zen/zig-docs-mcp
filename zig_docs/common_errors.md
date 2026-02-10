# Common Compilation Errors Quick Reference

Search this page for your error message to find the fix immediately.

## Table of Contents
- [Pointer and Mutability Errors](#pointer-and-mutability-errors)
- [String and C Interop Errors](#string-and-c-interop-errors)
- [Missing API Errors (Zig 0.16)](#missing-api-errors-zig-016)
- [Function Signature Errors](#function-signature-errors)
- [Allocator Errors](#allocator-errors)
- [Import and Module Errors](#import-and-module-errors)

---

## Pointer and Mutability Errors

### "expected type '*T', found '*const T'"

**Cause:** Trying to call a mutable method on a const pointer capture

**Where it happens:**
- `errdefer if (...) |*result|` - pointer capture creates `*const T`
- `if (...) |*val|` when val needs to be mutated
- `catch |*err|` when trying to modify error value

**Fix - Capture by value, assign to var:**
```zig
// ❌ BAD: Pointer capture in errdefer
errdefer if (self.cleanup()) |*result| {
    result.deinit();  // ERROR: result is *const
}

// ✅ GOOD: Value capture, then var
errdefer if (self.cleanup()) |val| {
    var result = val;  // Now mutable
    result.deinit();   // OK
}
```

**Example from real code:**
```zig
// Indexer cleanup pattern
var partial_index: ?Index = null;
errdefer if (partial_index) |idx| {  // ✅ Value capture
    var index = idx;                 // Make mutable
    index.deinit();                  // Can call deinit
};
```

---

### "cannot assign to constant"

**Cause:** Trying to modify a const variable or field

**Fix - Use var instead of const:**
```zig
// ❌ BAD
const x = 5;
x = 10;  // ERROR

// ✅ GOOD
var x = 5;
x = 10;  // OK
```

**In capture patterns:**
```zig
// ❌ BAD
if (optional) |*val| {
    val.field = 42;  // ERROR: val is *const
}

// ✅ GOOD
if (optional) |val| {
    var mutable = val;
    mutable.field = 42;  // OK
}
```

---

## String and C Interop Errors

### "expected type '[:0]const u8', found '[]const u8'"

**Cause:** C function needs null-terminated string, but you have a regular slice

**Fix - Add null terminator (Zig 0.16):**
```zig
// For dynamic strings
const str = try std.fmt.allocPrint(allocator, "value: {}", .{value});
defer allocator.free(str);

const str_z = try allocator.dupeZ(u8, str);  // ✅ Add null terminator
defer allocator.free(str_z);

c_function(str_z);  // Now works
```

**For string literals:**
```zig
// String literals are ALREADY null-terminated
const str = "hello";  // Type is [:0]const u8
c_function(str);  // Works directly
```

**For fixed buffers:**
```zig
var buffer: [256:0]u8 = undefined;  // ✅ Reserve space for null terminator
const str = try std.fmt.bufPrint(&buffer, "value: {}", .{42});
buffer[str.len] = 0;  // Add null terminator
c_function(&buffer);
```

---

### "no member named 'allocPrintZ' in struct 'std.fmt'"

**Cause:** `allocPrintZ` was removed in Zig 0.16

**Fix - Use allocPrint + dupeZ:**
```zig
// ❌ OLD (pre-0.16)
const str = try std.fmt.allocPrintZ(allocator, "value: {}", .{val});
defer allocator.free(str);

// ✅ NEW (0.16+)
const str = try std.fmt.allocPrint(allocator, "value: {}", .{val});
defer allocator.free(str);
const str_z = try allocator.dupeZ(u8, str);
defer allocator.free(str_z);

// Or if you don't need the non-null-terminated version:
const str = try std.fmt.allocPrint(allocator, "value: {}", .{val});
const str_z = try allocator.dupeZ(u8, str);
allocator.free(str);  // Free original immediately
defer allocator.free(str_z);
```

---

## Missing API Errors (Zig 0.16)

### "root source file has no member 'X'"

**Cause:** API moved or removed in Zig 0.16

**Common cases and fixes:**

| Old API | New API (0.16) |
|---------|----------------|
| `std.net.*` | `std.Io.net.*` |
| `std.fs.File` | `std.Io.File` |
| `std.fs.Dir` | `std.Io.Dir` |
| `std.time.timestamp()` | `std.Io.Clock.real.now(io)` |
| `std.time.milliTimestamp()` | `std.Io.Clock.real.now(io)` |
| `std.fmt.allocPrintZ()` | `std.fmt.allocPrint()` + `allocator.dupeZ()` |

**Example fixes:**

```zig
// ❌ OLD: std.net
const std = @import("std");
const addr = try std.net.Address.parseIp4("127.0.0.1", 8080);

// ✅ NEW: std.Io.net
const std = @import("std");
const net = std.Io.net;
const addr = try net.IpAddress.parse("127.0.0.1", 8080);
```

```zig
// ❌ OLD: std.time.timestamp()
const timestamp = std.time.timestamp();

// ✅ NEW: std.Io.Clock.real.now()
const io = threaded.io();  // Get io from somewhere
const ts = try std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
```

**See also:** [migration_016.md](migration_016.md) for complete migration guide

---

## Function Signature Errors

### "member function expected N arguments, found M"

**Cause:** Function signature changed in Zig 0.16 (often added 'io' or 'allocator' parameter)

**Common patterns:**

#### ArrayList methods now need allocator
```zig
// ❌ OLD
var list = std.ArrayList(u32).init(allocator);
try list.append(42);
list.deinit();

// ✅ NEW (0.16)
var list = std.ArrayList(u32).empty;
try list.append(allocator, 42);  // Pass allocator
list.deinit(allocator);           // Pass allocator
```

#### Filesystem methods now need io
```zig
// ❌ OLD
try dir.makePath("foo/bar");

// ✅ NEW (0.16)
try dir.createDirPath(io, "foo/bar");  // Pass io
```

#### Method name changes
```zig
// ❌ OLD
try dir.makePath("path");
try dir.deleteTree("path");

// ✅ NEW (0.16)
try dir.createDirPath(io, "path");
try dir.deleteDir(io, "path");
```

---

## Allocator Errors

### "parameter of type 'std.mem.Allocator' not used"

**Cause:** ArrayList and other containers became "unmanaged" in 0.16, so you don't store the allocator

**Fix:**
```zig
// ❌ OLD: Store allocator
var list = std.ArrayList(u32).init(allocator);

// ✅ NEW: Don't store allocator, pass it each time
var list = std.ArrayList(u32).empty;
try list.append(allocator, 42);
list.deinit(allocator);
```

---

### "expected type 'std.mem.Allocator', found 'std.heap.GeneralPurposeAllocator(...)'"

**Cause:** Need to call `.allocator()` to get the Allocator interface

**Fix:**
```zig
// ❌ BAD: Passing GPA directly
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var list = std.ArrayList(u32).empty;
try list.append(gpa, 42);  // ERROR

// ✅ GOOD: Call .allocator()
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
try list.append(gpa.allocator(), 42);  // OK
```

---

## Import and Module Errors

### "unable to find 'X' in module 'std'"

**Cause:** Module moved or renamed in Zig 0.16

**Common moves:**
- `std.net` → `std.Io.net`
- `std.fs` → `std.Io` (for File, Dir)
- `std.time` → `std.Io.Clock` (for timestamps)

**Fix:**
```zig
// ❌ OLD
const net = @import("std").net;

// ✅ NEW
const std = @import("std");
const net = std.Io.net;
```

---

### "import of file outside module path"

**Cause:** Trying to import a file that's not in your project structure

**Fix - Use proper module structure:**
```zig
// ❌ BAD: Relative path outside module
const other = @import("../../external/file.zig");

// ✅ GOOD: Add to build.zig modules
// In build.zig:
const external = b.addModule("external", .{
    .root_source_file = .{ .path = "external/file.zig" },
});
exe.root_module.addImport("external", external);

// In your code:
const external = @import("external");
```

---

## Build System Errors

### "dependency on library 'c' not found"

**Cause:** Trying to use C library without linking libc

**Fix - Add to build.zig:**
```zig
// In build.zig
exe.linkLibC();  // Add this line
```

**Or for tests:**
```bash
# Command line
zig test file.zig -lc
```

---

### "use of undeclared identifier 'addLibraryPath'"

**Cause:** `addLibraryPath` was removed in Zig 0.16

**Fix - Use linkSystemLibrary:**
```zig
// ❌ OLD (pre-0.16)
exe.addLibraryPath(.{ .path = "/usr/lib" });
exe.linkSystemLibrary("pq");

// ✅ NEW (0.16)
exe.linkSystemLibrary("pq");  // Zig finds system libraries automatically
// Or specify path in system environment: PKG_CONFIG_PATH, LIBRARY_PATH
```

---

## Memory Errors

### "memory leak detected"

**Cause:** Allocated memory not freed

**Fix - Use defer:**
```zig
// ❌ BAD: No cleanup
const buffer = try allocator.alloc(u8, 1024);
// ... use buffer ...
// If error happens, memory leaks

// ✅ GOOD: Immediate defer
const buffer = try allocator.alloc(u8, 1024);
defer allocator.free(buffer);  // Always cleaned up
```

**For multi-step allocation:**
```zig
// ✅ Use errdefer for each step
const buf1 = try allocator.alloc(u8, 1024);
errdefer allocator.free(buf1);  // Only if subsequent error

const buf2 = try allocator.alloc(u8, 2048);
errdefer allocator.free(buf2);

return .{ .a = buf1, .b = buf2 };  // Caller now owns both
```

---

## Error Handling Errors

### "expected type '!void', found 'void'"

**Cause:** Function declared as returning error, but doesn't propagate errors

**Fix:**
```zig
// ❌ BAD: Declared as !void but doesn't handle errors
fn process() !void {
    doSomething();  // If this can error, must handle
}

// ✅ GOOD: Propagate with try
fn process() !void {
    try doSomething();  // Propagate errors
}

// ✅ OR: Remove ! if no errors
fn process() void {
    doSomething();
}
```

---

### "error is ignored"

**Cause:** Error union result not handled

**Fix:**
```zig
// ❌ BAD: Ignoring error
_ = doSomething();  // Compiler warning/error

// ✅ GOOD: Handle explicitly
try doSomething();  // Propagate

// ✅ OR: Explicitly ignore if intentional
doSomething() catch {};  // OK if you really want to ignore
```

---

## Quick Reference: Zig 0.16 API Changes

| Error Message | Old API | New API |
|---------------|---------|---------|
| "no member 'allocPrintZ'" | `std.fmt.allocPrintZ()` | `std.fmt.allocPrint()` + `allocator.dupeZ()` |
| "no member 'net'" | `std.net.Address` | `std.Io.net.IpAddress` |
| "no member 'timestamp'" | `std.time.timestamp()` | `std.Io.Clock.real.now(io)` |
| "expected N arguments, found M" (ArrayList) | `list.append(item)` | `list.append(allocator, item)` |
| "expected N arguments, found M" (fs) | `dir.makePath(path)` | `dir.createDirPath(io, path)` |

---

## See Also

- [error_patterns.md](error_patterns.md) - Practical error handling patterns
- [memory_patterns.md](memory_patterns.md) - Memory management patterns
- [migration_016.md](migration_016.md) - Complete Zig 0.16 migration guide
- [c.md](c.md) - C interop including null-terminated strings
