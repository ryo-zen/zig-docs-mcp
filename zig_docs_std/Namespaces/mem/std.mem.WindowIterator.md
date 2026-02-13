# std.mem.WindowIterator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.WindowIterator.tests.zig)**

## Overview

`WindowIterator` provides a sliding window view over a buffer, yielding fixed-size overlapping or non-overlapping slices. This is useful for algorithms that process data in chunks, implement n-gram analysis, or perform rolling computations.

The iterator maintains a current position and advances by a configurable step size, allowing both overlapping windows (like n-grams with `advance = 1`) and non-overlapping tiles (like chunking with `advance = window_size`).

**Common use cases**:
- Text analysis (bigrams, trigrams, n-grams)
- Signal processing (overlapping FFT windows)
- Pattern matching over sequences
- Chunked data processing

**Created by**: Call `std.mem.window(T, buffer, window_size, advance)` to create an iterator instance.

## Parameters

`T: type`

The element type of the buffer being iterated over.

## Fields

`buffer: []const T`

The complete input buffer being windowed over. The iterator provides read-only views into this buffer.

------

`index: ?usize`

Current position in the buffer. `null` indicates the iterator is exhausted. Starts at `0` for the first window.

------

`size: usize`

The fixed size of each window (number of elements per slice). All windows returned by `next()` have this length, except possibly the final window if the buffer length is not evenly divisible.

------

`advance: usize`

The number of elements to advance after each window. Controls overlap:
- `advance = 1`: Maximum overlap (each element appears in `size` windows)
- `advance = size`: No overlap (adjacent non-overlapping chunks)
- `advance < size`: Partial overlap
- `advance > size`: Gaps between windows (some elements skipped)

## Functions

### `pub fn next(self: *Self) ?[]const T`

Returns a slice containing the next window, or `null` when the iteration is complete.

**Return value**:
- `[]const T` slice of length `size` (or shorter for the final partial window)
- `null` when no more windows are available

**Iteration termination**: Stops when the current position plus window size exceeds the buffer length.

**Example**:
```zig
var iter = std.mem.window(u8, "abcdef", 3, 1);
// Returns: "abc", "bcd", "cde", "def", then null
```

------

### `pub fn reset(self: *Self) void`

Resets the iterator to the initial state, allowing re-iteration from the beginning.

**Effect**: Sets `index` back to `0` (or `null` if buffer is empty).

**Use when**: You need to iterate over the same buffer multiple times without recreating the iterator.

**Example**:
```zig
var iter = std.mem.window(u8, data, 4, 2);
while (iter.next()) |window| { /* first pass */ }
iter.reset();
while (iter.next()) |window| { /* second pass */ }
```

## Usage Examples

### Overlapping Windows (N-grams)

```zig
const std = @import("std");

// Bigrams (2-character windows with advance=1)
var iter = std.mem.window(u8, "hello", 2, 1);
// Yields: "he", "el", "ll", "lo"

while (iter.next()) |bigram| {
    std.debug.print("{s}\n", .{bigram});
}
```

### Non-Overlapping Chunks

```zig
// Process data in non-overlapping 4-byte chunks
var iter = std.mem.window(u8, buffer, 4, 4);

while (iter.next()) |chunk| {
    // Process each 4-byte chunk independently
    processChunk(chunk);
}
```

### ASCII Art Visualization

```
Buffer:     [A][B][C][D][E][F][G]
Window size: 3
Advance: 1

Windows:
  [A B C]─┐
    [B C D]─┐
[C D E]─┐
  [D E F]─┐
    [E F G]

Advance: 2

Windows:
  [A B C]───┐
  [C D E]───┐
      [E F G]

Advance: 3 (non-overlapping)

Windows:
  [A B C]──────┐
         [D E F]──────┐
```

## Performance Considerations

- **No allocation**: `WindowIterator` creates views into the existing buffer without copying
- **Constant time iteration**: Each `next()` call is O(1)
- **Minimal state**: Only tracks current index and configuration

Choose `advance` based on your needs:
- Smaller advance values increase the number of windows (more work)
- Larger advance values reduce overlap (better cache locality for independent processing)
