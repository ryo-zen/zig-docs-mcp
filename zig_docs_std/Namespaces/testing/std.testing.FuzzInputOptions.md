# std.testing.FuzzInputOptions

**Type:** `struct`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

Configuration options for fuzz testing input generation. Provides a corpus of seed inputs to guide the fuzzer toward interesting test cases.

**Use Case:** Property-based testing and fuzz testing where you want to provide known-interesting inputs to the fuzzer.

---

## Fields

### `corpus: []const []const u8 = &.{}`

A slice of byte slices representing seed inputs for the fuzzer. Each entry is a test case that will be used to generate variations.

**Default:** Empty slice (no corpus)

---

## Usage

```zig
const std = @import("std");

test "fuzz with corpus" {
    const corpus = &[_][]const u8{
  "hello",
  "world",
  "\x00\xff\x00",  // Binary data
  "edge case with unicode: 👋",
    };

    // Configure fuzzing with corpus
    const options: std.testing.FuzzInputOptions = .{
  .corpus = corpus,
    };

    // Use with fuzz testing framework (when available)
    // Note: Zig's fuzz testing is still evolving
}
```

---

## Source

```zig
pub const FuzzInputOptions = struct {
    corpus: []const []const u8 = &.{},
};
```

---

## Related

- **[std.testing main docs](./std.testing.md)** - Complete testing guide
- **[std.testing.random_seed](./std.testing.random_seed.md)** - Deterministic randomness for tests

---

## Best Practices

✅ **Provide edge cases** - Include boundary conditions in corpus
✅ **Mix valid and invalid inputs** - Test both happy and error paths
✅ **Include real-world data** - Use actual inputs from production when possible
⚠️ **Keep corpus manageable** - Too many seeds can slow down fuzzing
