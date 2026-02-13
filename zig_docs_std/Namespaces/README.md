# Namespace Documentation Pattern

This document explains the standard structure for documenting Zig standard library namespaces.

## File Naming Convention

```
std.{namespace}.md
```

Examples:
- `std.fmt.md` - Formatting and parsing
- `std.heap.md` - Memory allocation
- `std.fs.md` - File system operations
- `std.testing.md` - Test utilities

## Structure Overview

Every namespace documentation file should follow this structure (in order):

1. **Title** - `# std.{namespace}`
2. **Examples Link** - Link to runnable test examples
3. **Quick Start** - Most common patterns (3-5 examples)
4. **Common Operations Table** (optional) - Quick reference
5. **Critical Warning** (if applicable) - Most important gotcha
6. **Horizontal Rule** (`---`)
7. **Overview** - What it is, key characteristics, when to use
8. **Core Types** (if applicable) - Main types users work with
9. **Functions** - Grouped by category, each with examples
10. **Usage Patterns** - 3-5 realistic end-to-end examples
11. **Types and Constants** - All types, enums, constants
12. **Error Sets** - All error types
13. **Debug Checklist** - Common mistakes and what to verify
14. **Performance Tips** - 5-7 actionable optimization tips
15. **See Also** - Related namespaces and alternatives

## Section Details

### 1. Title & Examples Link

```markdown
# std.fmt

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all fmt features
```

**Purpose:** Immediate orientation and link to working code.

### 2. Quick Start

**Goal:** Get users productive in 30 seconds.

```markdown
## Quick Start

### Most Common Patterns

**Stack-Allocated Formatting (No Allocator)**
```zig
var buffer: [1024]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "Hello, {s}!", .{"World"});
```

**Heap-Allocated Formatting**
```zig
const allocator = std.heap.page_allocator;
const message = try std.fmt.allocPrint(allocator, "Value: {d}", .{42});
defer allocator.free(message);
```
```

**Best Practices:**
- Show **most common** use cases first (not comprehensive)
- Keep examples **minimal** (5-10 lines max)
- Use **descriptive pattern names** ("Stack-Allocated Formatting" not "Example 1")
- Show **complete, runnable code** (include imports if non-obvious)
- Maximum 5 quick start patterns

### 3. Common Operations Table (Optional)

```markdown
| Operation | Function | Example |
|-----------|----------|---------|
| Format to buffer | `bufPrint()` | `std.fmt.bufPrint(&buf, "{}", .{x})` |
| Parse integer | `parseInt()` | `std.fmt.parseInt(i32, "42", 10)` |
```

**When to include:** Namespaces with many discrete operations (fmt, math, mem). Skip for simple namespaces.

### 4. Critical Warning (If Applicable)

```markdown
### ⚠️ Critical: Buffer Sizing
```zig
// TOO SMALL - Will return error.NoSpaceLeft!
var tiny: [5]u8 = undefined;
const result = std.fmt.bufPrint(&tiny, "Hello, World!", .{}); // ERROR!

// Correct - Always size buffer larger than needed
var buffer: [100]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "Hello, World!", .{}); // ✅
```
```

**When to include:** If there's ONE gotcha that trips up most users.

### 5. Overview

```markdown
## Overview

`std.fmt` is Zig's string formatting and parsing namespace, providing compile-time format string validation, type-safe formatting, and robust parsing utilities.

**Key Characteristics:**
- **Compile-time format validation** - Format strings must be `comptime` known
- **Type-safe** - Format specifiers automatically matched
- **Zero-allocation options** - `bufPrint` works with stack buffers

**When to use std.fmt:**
- Converting numbers to strings for display or logging
- Parsing user input from command-line args or config files
- Formatting error messages and debug output
```

**Structure:**
1. One-sentence description of what it is
2. **Key Characteristics** - 4-6 bullet points of distinguishing features
3. **When to use** - 3-5 concrete use cases

### 6. Functions Section

**Group by category:**

```markdown
## Formatting Functions

### `pub fn bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype) ![]u8`

Formats into a stack-allocated buffer. Most common formatting function.

**Parameters:**
- `buf` - Destination buffer (must be large enough)
- `fmt` - Compile-time format string
- `args` - Tuple of arguments matching format specifiers

**Returns:** Slice of `buf` containing formatted data

**Errors:** `error.NoSpaceLeft` if buffer is too small

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var buffer: [100]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buffer, "User {s} has {d} points", .{"Alice", 42});
    std.debug.print("{s}\n", .{msg});
}
```

------
```

**Best Practices:**
- **Full function signature** in heading (with backticks)
- **Brief description** (1 sentence what it does)
- **Parameters** section if non-obvious
- **Returns** description
- **Errors** if function returns error union
- **Complete, runnable example** (15-25 lines ideal)
- **Separator** (`------`) between functions in same category

### 7. Usage Patterns

**Show realistic, multi-step examples:**

```markdown
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
}
```
```

**Guidelines:**
- 3-5 patterns showing different real-world scenarios
- Complete, copy-paste-able examples (20-40 lines)
- Descriptive pattern names (not "Example 1")
- Show how namespace integrates with other stdlib features

### 8. Types and Constants

```markdown
## Types and Constants

### User-Facing Types

**`Case` (enum)**
```zig
pub const Case = enum { lower, upper };
```
Used with `bytesToHex` to specify letter case.

**Example:**
```zig
const hex = std.fmt.bytesToHex("Hi", .lower);
```

------

### Internal Types (Advanced Use)

**`Parser` (struct)**
Stream-based parser for format strings. Used internally but available for custom formatters.

------

### Constants

**`default_max_depth: usize`**
Maximum recursion depth for debug formatting.
```

**Organization:**
1. **User-Facing Types** - Types users commonly interact with
2. **Internal Types** - Advanced/rare usage, clearly labeled
3. **Constants** - Named constants with descriptions

### 9. Error Sets

```markdown
## Error Sets

### `BufPrintError`
- `error.NoSpaceLeft` - Buffer too small for formatted output

### `ParseIntError`
- `error.Overflow` - Number too large for target type
- `error.InvalidCharacter` - Non-digit character in input
```

**Simple list format** - error set name, then errors with brief descriptions.

### 10. Debug Checklist

```markdown
## Debug Checklist

✅ **Format string is `comptime` known** - Cannot use runtime strings

✅ **Buffer is large enough** - Use `count()` to pre-calculate size

✅ **Number of arguments matches specifiers** - `"{d}"` needs exactly 1 argument

✅ **Free allocated strings** - `allocPrint` returns owned memory
```

**Purpose:** Quick checklist of common mistakes and things to verify.

**Format:**
- 5-10 items
- Start with ✅ emoji
- **Bold** the key point
- Brief explanation after dash

### 11. Performance Tips

```markdown
## Performance Tips

1. **Prefer `bufPrint` over `allocPrint`** - Stack allocation is faster and doesn't fragment the heap. Use `allocPrint` only when size is truly unknown.

2. **Pre-calculate buffer sizes** - Use `std.fmt.count()`:
   ```zig
   const size = std.fmt.count("Value: {d}", .{12345});
   var buffer: [size]u8 = undefined;
   ```

3. **Reuse buffers** - Don't allocate a new buffer for each operation
```

**Guidelines:**
- 5-7 actionable tips
- Numbered list
- **Bold** the tip title
- Include code examples where helpful
- Order by impact (most important first)

### 12. See Also

```markdown
## See Also

- **std.mem** - Memory utilities (slicing, comparison, searching)
- **std.Io.Writer** - Streaming formatted output
- **std.debug.print** - Quick debug printing (uses fmt internally)
```

**Purpose:** Help users discover related functionality.

**Format:**
- Bullet list
- **Bold** the namespace name
- Brief description of relationship

---

## Real Examples

See these namespace docs as reference implementations:

- **`std.fmt.md`** - Comprehensive example (formatting + parsing)
- **`std.heap.md`** - Allocator-focused namespace
- **`NAMESPACE_TEMPLATE.md`** - Copy-paste template

## Quality Checklist

Before submitting namespace documentation:

- [ ] All sections present in correct order
- [ ] Quick Start has 3-5 minimal, runnable examples
- [ ] Overview explains what, why, and when
- [ ] Every function has a complete example
- [ ] Usage Patterns show realistic multi-step scenarios
- [ ] All types documented (even internal ones)
- [ ] Error sets listed with descriptions
- [ ] Debug checklist has 5-10 items
- [ ] Performance tips are actionable with examples
- [ ] Created test file in `Examples/{namespace}.tests.zig`
- [ ] All tests pass: `zig test Examples/{namespace}.tests.zig`
- [ ] Horizontal rules (`------`) separate items within sections
- [ ] Horizontal rule (`---`) separates major sections

## Writing Style

- **Active voice** - "Formats into buffer" not "Buffer is formatted into"
- **Present tense** - "Returns a slice" not "Will return a slice"
- **Concise** - Get to the point quickly
- **Code-first** - Show don't tell; examples over prose
- **Complete examples** - Every example should be copy-paste runnable
- **Type annotations** - Include types in function signatures for clarity
