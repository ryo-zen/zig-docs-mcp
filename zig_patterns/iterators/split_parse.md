# Pattern: Split and Parse (Tokenization)

**Problem**: How to parse delimited text (CSV, logs, config files) efficiently?

**When to use**:
- Parsing CSV, TSV, or custom delimited formats
- Processing log files with structured fields
- Tokenizing command-line input or config files
- Splitting paths, URLs, or other structured strings

**Alternatives**:
- indexOf + manual slicing (verbose, error-prone)
- Regular expressions (not available in Zig stdlib, overkill for simple delimiters)
- String.split() in other languages (Zig provides iterators instead)

---

## Basic Example: CSV Parsing

```zig
const std = @import("std");

const csv_line = "Alice,30,Engineer";
var iter = std.mem.splitScalar(u8, csv_line, ',');

const name = iter.next().?;     // "Alice"
const age = iter.next().?;      // "30"
const title = iter.next().?;    // "Engineer"
```

---

## Pattern: Whitespace Tokenization

```zig
// Split on any whitespace character
const text = "one\ttwo   three\nfour";
var iter = std.mem.tokenizeAny(u8, text, " \t\n");

while (iter.next()) |token| {
    // Process non-empty tokens
    std.debug.print("{s}\n", .{token});
}
// Output: "one", "two", "three", "four"
```

---

## Choosing the Right Iterator

### `split*` - Preserves empty fields
```zig
// "a,,b" with splitScalar → "a", "", "b"
```

### `tokenize*` - Skips empty fields
```zig
// "a,,b" with tokenizeScalar → "a", "b"
```

### Delimiter Types
- **`.scalar`**: Single character (fastest)
- **`.any`**: Any char from a set (e.g., whitespace)
- **`.sequence`**: Multi-char substring (e.g., "::")

---

## Real-World Example: Log Parsing

```zig
// TODO: Add complete log file parser
// See: ../../zig_docs_std/Examples/std.mem.DelimiterType.tests.zig
```

---

## Common Mistakes

- ❌ **Using split when you want tokenize**: Empty fields clutter results
- ❌ **Using .any for literal strings**: `.any` treats each char independently
- ❌ **Forgetting to handle empty input**: splitScalar("", ',') returns one empty field

---

## Performance Tips

1. **Prefer `.scalar` for single-char delimiters**: Fastest option
2. **Use `.sequence` for multi-char delimiters**: Don't split manually
3. **Backward iteration for suffix extraction**: `splitBackwards*` for paths/URLs

---

## See Also

- [DelimiterType Documentation](../../zig_docs_std/Namespaces/mem/std.mem.DelimiterType.md)
- [SplitIterator Documentation](../../zig_docs_std/Namespaces/mem/std.mem.SplitIterator.md)
- [SplitBackwardsIterator Documentation](../../zig_docs_std/Namespaces/mem/std.mem.SplitBackwardsIterator.md)
- [DelimiterType Tests](../../zig_docs_std/Examples/std.mem.DelimiterType.tests.zig)
