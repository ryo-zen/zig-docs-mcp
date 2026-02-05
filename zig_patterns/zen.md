# The Zen of Zig

Zig's guiding philosophy and design principles that shape how patterns should be written.

---

## Communicate intent precisely.

**What it means**: Code should clearly express what it does without ambiguity. Use explicit types, clear names, and avoid hidden control flow.

**In practice**:
```zig
// ✅ Intent is clear
const result = try parseNumber(input);

// ❌ Hidden behavior
const result = parseNumber(input); // throws? returns null? unclear
```

**Related patterns**:
- [Error Propagation](errors/try_propagation.md) - `try` makes error handling explicit
- [Custom Error Sets](errors/custom_error_sets.md) - Specific errors communicate intent

---

## Edge cases matter.

**What it means**: Don't ignore boundary conditions, empty inputs, or unlikely scenarios. Handle them explicitly.

**In practice**:
```zig
// ✅ Handles empty case
if (buffer.len == 0) return error.EmptyBuffer;

// ❌ Assumes non-empty
const first = buffer[0]; // crashes on empty buffer
```

**Related patterns**:
- [Split/Parse Pattern](iterators/split_parse.md) - Handling empty fields
- [Window Iteration](iterators/window_iteration.md) - Partial final windows

---

## Favor reading code over writing code.

**What it means**: Code is read far more often than written. Optimize for clarity and maintainability over clever brevity.

**In practice**:
```zig
// ✅ Clear and readable
const bytes_per_kilobyte = 1024;
const total_kb = bytes / bytes_per_kilobyte;

// ❌ Clever but unclear
const x = b >> 10; // what is this calculating?
```

**Impact on patterns**:
- Verbose names for clarity
- Explicit error handling over exceptions
- Straightforward control flow

---

## Only one obvious way to do things.

**What it means**: Avoid providing multiple equivalent APIs that do the same thing. Consistency reduces cognitive load.

**In practice**:
```zig
// ✅ Clear distinction in purpose
std.mem.splitScalar()  // preserves empty fields
std.mem.tokenizeScalar() // skips empty fields

// Each function has a specific use case, not arbitrary alternatives
```

**Related patterns**:
- [Split vs Tokenize](iterators/split_parse.md#choosing-the-right-iterator)
- [Delimiter Types](iterators/split_parse.md#delimiter-types) - Specific functions for specific needs

---

## Runtime crashes are better than bugs.

**What it means**: If something goes wrong, fail loudly and immediately rather than continuing with corrupt state.

**In practice**:
```zig
// ✅ Fails immediately on invalid state
if (index >= buffer.len) return error.IndexOutOfBounds;

// ❌ Silent corruption
buffer[index] = value; // undefined behavior if out of bounds
```

**Zig provides**:
- Assertions in Debug mode
- Bounds checking by default
- Explicit error handling

**Related patterns**:
- [Error Propagation](errors/try_propagation.md) - Explicit failure paths
- [Testing with Allocators](testing/allocator_testing.md) - Catch bugs early

---

## Compile errors are better than runtime crashes.

**What it means**: Catch mistakes at compile time whenever possible. Use the type system to enforce correctness.

**In practice**:
```zig
// ✅ Compile-time validation
fn processBuffer(comptime size: usize) void {
    if (size == 0) @compileError("Buffer size must be non-zero");
    var buffer: [size]u8 = undefined;
    // ...
}

// Catches errors before running
processBuffer(0); // Compile error: Buffer size must be non-zero
```

**Related patterns**:
- [Compile-Time Validation](comptime/compile_time_validation.md)
- [Generic Functions](comptime/generic_functions.md) - Type safety at compile time

---

## Incremental improvements.

**What it means**: Make small, testable changes rather than large rewrites. Refactor gradually.

**In practice**:
- Start with working code
- Add one feature at a time
- Test each change
- Avoid "big bang" refactors

**Applied to patterns**:
- Patterns show minimal examples first
- Build complexity incrementally
- Each pattern focuses on one concept

---

## Avoid local maximums.

**What it means**: Don't optimize for the immediate problem if it prevents better long-term solutions. Think holistically.

**In practice**:
```zig
// ❌ Local maximum: fast but inflexible
const buffer: [1024]u8 = undefined; // fixed size

// ✅ Better long-term: flexible and composable
const dynamic_buffer = try allocator.alloc(u8, needed_size);
defer allocator.free(dynamic_buffer);
```

**Related patterns**:
- [Arena Allocator](memory/arena_allocator.md) - Flexible memory management
- [Defer Cleanup](memory/defer_cleanup.md) - Composable resource management

---

## Reduce the amount one must remember.

**What it means**: Consistent conventions and predictable behavior reduce cognitive load. Don't require memorizing special cases.

**In practice**:
- Consistent naming conventions
- Predictable function behavior
- Standard patterns across stdlib

**Examples**:
- `init()` / `deinit()` pairs
- `try` always propagates errors
- `defer` always runs cleanup

**Related patterns**:
- [Defer Cleanup](memory/defer_cleanup.md) - Automatic cleanup, no manual tracking

---

## Focus on code rather than style.

**What it means**: Correctness and clarity matter more than stylistic preferences. Use `zig fmt` and move on.

**In practice**:
- `zig fmt` enforces consistent formatting
- No debates about tabs vs spaces
- Focus energy on logic, not layout

**Applied to patterns**:
- All examples are `zig fmt` compliant
- Patterns focus on semantics, not syntax

---

## Resource allocation may fail; resource deallocation must succeed.

**What it means**: Accept that allocation can fail (OutOfMemory). But once allocated, cleanup must be guaranteed.

**In practice**:
```zig
// ✅ Allocation can fail, cleanup guaranteed
const buffer = try allocator.alloc(u8, size); // may fail
defer allocator.free(buffer); // must succeed

// Cleanup runs even if error occurs later
try processData(buffer);
```

**Related patterns**:
- [Defer Cleanup](memory/defer_cleanup.md) - Guaranteed deallocation
- [errdefer Rollback](memory/errdefer_rollback.md) - Cleanup on error paths
- [Arena Allocator](memory/arena_allocator.md) - Bulk deallocation

---

## Memory is a resource.

**What it means**: Memory should be managed explicitly like any other resource. No garbage collection hiding complexity.

**In practice**:
- Explicit allocator parameters
- Manual memory management with tools to make it safe
- Defer and errdefer for RAII-style cleanup

**Zig provides**:
- Allocator abstraction for flexibility
- `defer`/`errdefer` for safety
- Debug allocators for leak detection

**Related patterns**:
- [Defer Cleanup](memory/defer_cleanup.md)
- [Arena Allocator](memory/arena_allocator.md)
- [Testing with Allocators](testing/allocator_testing.md)

---

## Together we serve the users.

**What it means**: Language design, library implementation, and application code all serve the end user. Optimize for their experience.

**In practice**:
- Performance without sacrificing clarity
- Safety without sacrificing control
- Simplicity without sacrificing power

**Applied to this documentation**:
- Patterns serve developers learning Zig
- Clear examples over academic correctness
- Practical solutions to real problems

---

## How Zen Guides Patterns

Each pattern in this directory embodies one or more Zen principles:

| Pattern | Primary Zen Principles |
|---------|------------------------|
| [Defer Cleanup](memory/defer_cleanup.md) | Resource deallocation must succeed; Reduce amount to remember |
| [Arena Allocator](memory/arena_allocator.md) | Memory is a resource; Avoid local maximums |
| [Error Propagation](errors/try_propagation.md) | Communicate intent precisely; Compile errors > runtime crashes |
| [Split/Parse](iterators/split_parse.md) | Only one obvious way; Edge cases matter |
| [Window Iteration](iterators/window_iteration.md) | Favor reading code; Edge cases matter |
| [Testing with Allocators](testing/allocator_testing.md) | Runtime crashes > bugs; Memory is a resource |

---

## See Also

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Pattern Index](README.md)
- [Memory Patterns](memory/)
- [Error Patterns](errors/)
