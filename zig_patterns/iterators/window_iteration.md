# Pattern: Window Iteration (Sliding Window)

**Problem**: How to process data in overlapping or non-overlapping fixed-size chunks?

**When to use**:
- N-gram analysis (bigrams, trigrams in text)
- Signal processing (overlapping FFT windows)
- Moving averages and rolling statistics
- Pattern matching over sequences
- Chunked data processing

**Alternatives**:
- Manual index arithmetic (error-prone, hard to read)
- Copying chunks to separate arrays (allocation overhead)
- Custom loop with offset tracking (reinventing the wheel)

---

## Basic Example: N-grams

```zig
const std = @import("std");

// Generate bigrams (2-character windows)
var iter = std.mem.window(u8, "hello", 2, 1);
while (iter.next()) |bigram| {
    std.debug.print("{s}\n", .{bigram});
}
// Output: "he", "el", "ll", "lo"
```

---

## Pattern: Non-Overlapping Chunks

```zig
// Process data in 4-byte chunks (no overlap)
var iter = std.mem.window(u8, buffer, 4, 4);
while (iter.next()) |chunk| {
    processChunk(chunk);
}
```

---

## Real-World Example: Moving Average

```zig
// TODO: Add complete moving average implementation
// See: ../../zig_docs_std/Examples/std.mem.WindowIterator.tests.zig
```

---

## Common Mistakes

- ❌ **Confusing size and advance**: `window(data, advance, size)` is wrong order
- ❌ **Not handling partial final window**: Last window may be shorter than size
- ❌ **Allocating for each window**: Windows are views, no allocation needed

---

## Performance Tips

1. **Window views are zero-copy**: No allocation per window
2. **Advance = size for maximum performance**: Non-overlapping windows are faster to process
3. **Small advance = more windows**: Consider batch processing for large datasets

---

## See Also

- [WindowIterator Documentation](../../zig_docs_std/Namespaces/mem/std.mem.WindowIterator.md)
- [WindowIterator Tests](../../zig_docs_std/Examples/std.mem.WindowIterator.tests.zig)
- [Split/Parse Pattern](split_parse.md)
