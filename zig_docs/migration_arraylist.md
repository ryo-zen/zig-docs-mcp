# ArrayList Migration Guide (0.16)

## Core Breaking Change

ArrayList no longer stores its allocator internally. All methods now require an allocator parameter.

## Constructor Changes

**Before (0.13-0.14):**
```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit();
```

**After (0.16):**
```zig
var list: std.ArrayList(u32) = .{};
defer list.deinit(allocator);
```

**Key differences:**
- Constructor: `.init(allocator)` → `.{}` (empty struct literal)
- Destructor: `deinit()` → `deinit(allocator)`

## Method Signature Changes

### append

**Before:**
```zig
try list.append(42);
```

**After:**
```zig
try list.append(allocator, 42);
```

### appendSlice

**Before:**
```zig
try list.appendSlice(&[_]u32{1, 2, 3});
```

**After:**
```zig
try list.appendSlice(allocator, &[_]u32{1, 2, 3});
```

### insert

**Before:**
```zig
try list.insert(0, 99);
```

**After:**
```zig
try list.insert(allocator, 0, 99);
```

### resize

**Before:**
```zig
try list.resize(100);
```

**After:**
```zig
try list.resize(allocator, 100);
```

### ensureTotalCapacity

**Before:**
```zig
try list.ensureTotalCapacity(1000);
```

**After:**
```zig
try list.ensureTotalCapacity(allocator, 1000);
```

## Complete Example

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create list
    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);

    // Add items
    try list.append(allocator, 42);
    try list.append(allocator, 100);
    try list.appendSlice(allocator, &[_]u32{200, 300});

    // Insert
    try list.insert(allocator, 0, 1);

    // Resize
    try list.resize(allocator, 10);

    // Capacity
    try list.ensureTotalCapacity(allocator, 100);

    std.debug.print("Items: {any}\n", .{list.items});
}
```

## Why This Change?

**Benefits:**
1. **Flexibility**: Can use different allocators for different operations
2. **No hidden state**: Allocator dependency is explicit
3. **Memory clarity**: Clear who owns what
4. **Smaller struct**: ArrayList is now just a slice + capacity

**Old way problems:**
```zig
// Before - allocator was hidden
fn processData(list: ArrayList(u32)) {
    // Which allocator is this using? Can't tell!
}
```

**New way clarity:**
```zig
// After - allocator is explicit
fn processData(allocator: Allocator, list: ArrayList(u32)) {
    try list.append(allocator, 42); // Clear ownership
}
```

## ArrayListUnmanaged

If you want the old behavior (manual allocator management), use `ArrayListUnmanaged`:

```zig
var list = std.ArrayListUnmanaged(u32){};
defer list.deinit(allocator);

try list.append(allocator, 42);
```

## Migration Checklist

- [ ] Replace `.init(allocator)` with `.{}`
- [ ] Add `allocator` parameter to `append()` calls
- [ ] Add `allocator` parameter to `appendSlice()` calls
- [ ] Add `allocator` parameter to `insert()` calls
- [ ] Add `allocator` parameter to `resize()` calls
- [ ] Add `allocator` parameter to `ensureTotalCapacity()` calls
- [ ] Add `allocator` parameter to `deinit()` calls
- [ ] Update function signatures that pass ArrayList
- [ ] Test with `std.testing.allocator` for leak detection

## Common Errors

### Error: "expected 2 arguments, found 1"

```zig
// Wrong
try list.append(42);

// Fixed
try list.append(allocator, 42);
```

### Error: "no member named 'init' in ArrayList"

```zig
// Wrong
var list = std.ArrayList(u32).init(allocator);

// Fixed
var list: std.ArrayList(u32) = .{};
```

### Error: "expected 1 argument, found 0"

```zig
// Wrong
list.deinit();

// Fixed
list.deinit(allocator);
```

## Testing Pattern

```zig
test "arraylist migration" {
    const allocator = std.testing.allocator;

    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    try std.testing.expectEqual(@as(usize, 1), list.items.len);
    try std.testing.expectEqual(@as(u32, 42), list.items[0]);
}
```
