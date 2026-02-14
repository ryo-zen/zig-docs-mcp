# std.testing.random_seed

**Type:** `u32`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A mutable variable that provides a deterministic random seed for unit tests. Initialized once at test runtime startup and should be treated as read-only afterward.

**Use Case:** When tests need deterministic randomness for reproducible test runs (e.g., fuzzing, property-based testing).

---

## Usage

```zig
const std = @import("std");

test "deterministic random behavior" {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const random = prng.random();

    const value = random.int(u32);
    // Same seed = same sequence every test run
    std.debug.print("Random value: {}\n", .{value});
}
```

---

## Source

```zig
pub var random_seed: u32 = 0;
```

**Initialization:** Set by the test runner before any tests execute.

---

## Related

- **[std.Random](./std.testing.md)** - Random number generation utilities
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Read-only in tests** - Don't modify this value in your tests
✅ **Use for reproducibility** - Same seed = same random sequence
⚠️ **Not cryptographically secure** - For testing only, not production randomness
