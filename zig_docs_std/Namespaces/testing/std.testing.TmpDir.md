# std.testing.TmpDir

**Type:** `struct`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A temporary directory for unit tests that provides automatic cleanup. Creates an isolated filesystem location for tests that need to read/write files without polluting the system or affecting other tests.

**Key Features:**
- ✅ Isolated test filesystem namespace
- ✅ Automatic cleanup via `cleanup()` method
- ✅ Tracks both the directory and its parent for proper deletion

---

## Fields

### `dir: Io.Dir`

The handle to the temporary directory itself. Use this for file operations within the temp directory.

------

### `parent_dir: Io.Dir`

The handle to the parent directory containing the temporary directory. Required for cleanup operations.

------

### `sub_path: [sub_path_len]u8`

Fixed-size buffer storing the name of the temporary directory (relative to parent). The length is determined by the `sub_path_len` constant.

---

## Functions

### `pub fn cleanup(self: *TmpDir) void`

Removes the temporary directory and all its contents. Call this when the test completes (typically via `defer`).

**Example:**
```zig
const std = @import("std");

test "working with temporary files" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // Create and write to files in tmp.dir
    const file = try tmp.dir.createFile("test.txt", .{});
    defer file.close();

    try file.writeAll("test data");
    // ... test operations ...

    // cleanup() is called automatically via defer
}
```

---

## Usage Patterns

### Basic Temporary Directory

```zig
test "temporary directory usage" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // Create a file in the temp directory
    var file = try tmp.dir.createFile("data.bin", .{});
    defer file.close();

    try file.writeAll("temporary test data");

    // Read it back
    const contents = try tmp.dir.readFileAlloc(
  std.testing.allocator,
  "data.bin",
  1024,
    );
    defer std.testing.allocator.free(contents);

    try std.testing.expectEqualStrings("temporary test data", contents);
}
```

### Nested Directory Structure

```zig
test "nested directories in tmpdir" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // Create subdirectories
    try tmp.dir.makeDir("subdir");
    var subdir = try tmp.dir.openDir("subdir", .{});
    defer subdir.close();

    // Work with nested structure
    var file = try subdir.createFile("nested.txt", .{});
    defer file.close();

    try file.writeAll("nested data");
}
```

---

## Related

- **[std.testing.tmpDir](./std.testing.md#tmpDir)** - Function to create a TmpDir instance
- **[std.Io.Dir](../../io/std.io.md)** - Directory handle operations
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Always cleanup** - Use `defer tmp.cleanup()` immediately after creation
✅ **Isolated tests** - Each test should create its own TmpDir
✅ **Don't hardcode paths** - Use the provided `dir` handle for operations
⚠️ **Cleanup is manual** - Not RAII - must explicitly call cleanup()
