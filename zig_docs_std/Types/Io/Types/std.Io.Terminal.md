# std.Io.Terminal

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating Terminal features

## Quick Start

### Most Common Patterns

**Basic Color Output**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

const term = stderr.terminal();
try term.setColor(.red);
try term.writer.writeAll("Error: Operation failed\n");
try term.setColor(.reset);
```

**Color-Coded Messages**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

const term = stderr.terminal();

// Success message
try term.setColor(.green);
try term.writer.writeAll("✓ Build successful\n");
try term.setColor(.reset);

// Warning message
try term.setColor(.yellow);
try term.writer.writeAll("⚠ Warning: Deprecated API\n");
try term.setColor(.reset);
```

**Conditional Color Support**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

const term = stderr.terminal();

// Only use color if terminal supports it
if (term.mode != .no_color) {
    try term.setColor(.blue);
}
try term.writer.writeAll("Building project...\n");
if (term.mode != .no_color) {
    try term.setColor(.reset);
}
```

### Key Operations
- `setColor(.red)` - Set foreground color
- `setColor(.reset)` - Reset to default color
- `.writer.writeAll()` - Write text to terminal
- `.mode` - Check terminal capabilities

### ⚠️ Critical: Always Reset Colors
```zig
try term.setColor(.red);
try term.writer.writeAll("Error message\n");
try term.setColor(.reset);  // ALWAYS reset after colored output!
```

---

## Overview

`std.Io.Terminal` provides an abstraction for interacting with terminal devices, offering capabilities like color output and mode detection. It wraps an underlying `Io.Writer` and adds terminal-specific control through ANSI escape sequences or OS-specific console APIs.

**Key Characteristics:**
- **Color support**: Automatically detects and uses appropriate color method (ANSI, Windows Console, or none)
- **Mode detection**: Identifies terminal capabilities based on environment (TTY detection, NO_COLOR env var)
- **Writer integration**: Works seamlessly with the standard `Io.Writer` interface
- **Cross-platform**: Handles platform differences (ANSI on Unix, Windows Console API on Windows)

**When to use Terminal:**
- Writing colored output to stderr/stdout (build tools, CLI apps)
- Formatting diagnostic messages (errors, warnings, success)
- Creating interactive command-line interfaces
- Any scenario requiring terminal color control

## Fields

`writer: *Io.Writer`

The underlying writer where all output is sent. Use `writer.writeAll()` to output text.

------

`mode: Mode`

The current configuration mode of the terminal, indicating whether colors are supported and how they should be rendered.

## Types

### Color

Enum representing standard terminal colors and control values.

**Values:**
- `auto` - Automatically detect color based on environment
- `black` - Black foreground
- `red` - Red foreground
- `green` - Green foreground
- `yellow` - Yellow foreground
- `blue` - Blue foreground
- `magenta` - Magenta foreground
- `cyan` - Cyan foreground
- `white` - White foreground
- `reset` - Reset to terminal default color

------

### Mode

Union representing the terminal's operational mode and color capabilities.

**Variants:**
- `no_color` - Terminal does not support colors (pipe, file, NO_COLOR env var set)
- `escape_codes` - Terminal supports ANSI escape sequences (most Unix terminals)
- `windows_api` - Terminal uses Windows Console API with handle and reset attributes (Windows cmd.exe, PowerShell)

## Core Functions

### `pub fn setColor(t: Terminal, color: Color) SetColorError!void`

Sets the text foreground color for subsequent write operations. The method used depends on the terminal mode:
- **escape_codes mode**: Writes ANSI escape sequences (e.g., `\x1b[31m` for red)
- **windows_api mode**: Calls Windows Console API functions
- **no_color mode**: No color codes are written (color changes are ignored)

**Parameters:**
- `color` - The desired `Color` enum value

**Behavior:**
Writes the appropriate control sequence to change the terminal foreground color. Does not affect previously written text. Color persists until `setColor` is called again or the terminal is reset.

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var buffer: [1024]u8 = undefined;
    const stderr = try io.lockStderr(&buffer, null);
    defer io.unlockStderr();

    const term = stderr.terminal();

    // Red error message
    try term.setColor(.red);
    try term.writer.writeAll("Error: File not found\n");
    try term.setColor(.reset);

    // Green success message
    try term.setColor(.green);
    try term.writer.writeAll("Success: Operation completed\n");
    try term.setColor(.reset);
}
```

------

### Usage Pattern: Multi-Color Output

```zig
const std = @import("std");

pub fn printStatus(term: *std.Io.Terminal, status: enum { success, warning, error_ }) !void {
    switch (status) {
  .success => {
      try term.setColor(.green);
      try term.writer.writeAll("✓ ");
  },
  .warning => {
      try term.setColor(.yellow);
      try term.writer.writeAll("⚠ ");
  },
  .error_ => {
      try term.setColor(.red);
      try term.writer.writeAll("✗ ");
  },
    }
    try term.setColor(.reset);
}
```

## Error Sets

### SetColorError

Errors that may occur when setting terminal colors.

**Errors:**
- `Unexpected` - An unexpected error occurred
- `WriteFailed` - An error occurred while writing the control sequence to the underlying writer

**Note:** When `mode` is `no_color`, `setColor()` does not return an error - it simply skips writing color codes.

## Debug Checklist

If your color output doesn't work, check:

1. ✅ Did you reset the color after setting it?
   ```zig
   // ❌ DON'T: Forget to reset
   try term.setColor(.red);
   try term.writer.writeAll("Error\n");

   // ✅ DO: Always reset
   try term.setColor(.red);
   try term.writer.writeAll("Error\n");
   try term.setColor(.reset);
   ```

2. ✅ Are you writing to a TTY?
   - Colors are automatically disabled when output is redirected to a file or pipe
   - Test in a real terminal, not by redirecting to a file

3. ✅ Did you check the `NO_COLOR` environment variable?
   - Terminal honors the `NO_COLOR` env var (https://no-color.org)
   - Unset it if testing color output: `unset NO_COLOR`

4. ✅ Are you using `lockStderr` correctly?
   ```zig
   // ✅ Recommended: Use io.lockStderr
   var buffer: [1024]u8 = undefined;
   const stderr = try io.lockStderr(&buffer, null);
   defer io.unlockStderr();
   const term = stderr.terminal();
   ```

5. ✅ Did you handle errors gracefully?
   ```zig
   // setColor doesn't error on no_color mode - it just skips color output
   term.setColor(.red) catch |err| {
 // Handle WriteFailed or Unexpected errors
 std.debug.print("Color error: {s}\n", .{@errorName(err)});
   };
   ```

6. ✅ Are you testing on Windows?
   - Windows behavior differs (uses Console API, not ANSI)
   - Modern Windows 10+ supports ANSI, but older versions may not

## Performance Tips

1. **Batch color changes**: Minimize `setColor()` calls by grouping same-colored output
   ```zig
   // ❌ DON'T: Set color for each line
   for (errors) |err| {
 try term.setColor(.red);
 try term.writer.print("{s}\n", .{err});
 try term.setColor(.reset);
   }

   // ✅ DO: Set color once for all lines
   try term.setColor(.red);
   for (errors) |err| {
 try term.writer.print("{s}\n", .{err});
   }
   try term.setColor(.reset);
   ```

2. **Check mode before coloring**: Skip color operations if terminal doesn't support them
   ```zig
   if (term.mode != .no_color) {
 try term.setColor(.green);
   }
   try term.writer.writeAll("Message\n");
   if (term.mode != .no_color) {
 try term.setColor(.reset);
   }
   ```

3. **Use reset sparingly**: Only reset when transitioning to default color
   - Don't reset between different colors - just call `setColor()` with the new color

4. **Consider buffering**: Terminal writes through `Io.Writer` which may be buffered
   - Ensure you flush when needed for immediate output

## See Also

- [std.Io.LockedStderr](std.Io.LockedStderr.md) - Provides thread-safe access to stderr with terminal support
- [std.Io.Writer](std.Io.Writer.md) - Underlying writer interface used by Terminal
- [NO_COLOR Standard](https://no-color.org) - Environment variable for disabling color output
