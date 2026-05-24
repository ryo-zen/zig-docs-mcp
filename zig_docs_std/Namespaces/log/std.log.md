# std.log

📚 **[See Comprehensive Examples & Tests](../../Examples/log.tests.zig)** - Complete runnable code demonstrating all logging features

## Quick Start

### Most Common Patterns

**Basic Logging (Default Scope)**
```zig
std.log.debug("Variable value: {d}", .{counter});
std.log.info("Server started on port {d}", .{8080});
std.log.warn("Memory usage at {d}%", .{usage});
std.log.err("Failed to connect: {s}", .{error_msg});
```

**Custom Scoped Logging**
```zig
const log = std.log.scoped(.mylib);

pub fn initialize() void {
    log.info("Library initialized", .{});
    log.debug("Config: {any}", .{config});
}
```

**Conditional Logging**
```zig
if (std.log.logEnabled(.debug, .default)) {
    // Expensive debug computation only runs if debug logging is enabled
    const stats = computeExpensiveStats();
    std.log.debug("Stats: {any}", .{stats});
}
```

**Custom Log Function (Override Default)**
```zig
// In build configuration or std.options
pub const std_options = struct {
    pub fn logFn(
  comptime level: std.log.Level,
  comptime scope: @TypeOf(.enum_literal),
  comptime format: []const u8,
  args: anytype,
    ) void {
  // Custom implementation: write to file, send to network, etc.
  const prefix = comptime "[{s}] {s}: ";
  std.debug.print(prefix ++ format ++ "\n", .{
      @tagName(level),
      @tagName(scope),
  } ++ args);
    }
};
```

**Setting Log Level**
```zig
// In build.zig or std.options
pub const std_options = struct {
    pub const log_level: std.log.Level = .info;  // Only info and above
};
```

### Log Levels Quick Reference

| Level | Function | When to Use |
|-------|----------|-------------|
| `.err` | `std.log.err()` | Something went wrong (recoverable or fatal) |
| `.warn` | `std.log.warn()` | Uncertain if something is wrong, worth investigating |
| `.info` | `std.log.info()` | General messages about program state |
| `.debug` | `std.log.debug()` | Detailed information useful only for debugging |

### ⚠️ Critical: Compile-Time Filtering
```zig
// INEFFICIENT - String formatting happens even if debug logging is disabled
std.log.debug("Expensive: {s}", .{buildExpensiveString()});  // ❌

// EFFICIENT - Only runs if debug logging is enabled
if (std.log.logEnabled(.debug, .default)) {
    std.log.debug("Expensive: {s}", .{buildExpensiveString()});  // ✅
}

// BEST - Use lazy evaluation or comptime checks
std.log.debug("Value: {d}", .{cheap_value});  // ✅ Argument evaluation is cheap
```

---

## Overview

`std.log` is Zig's standardized structured logging interface, providing compile-time filtered, scope-based logging with customizable output formatting. It allows libraries and applications to emit log messages that can be uniformly formatted, filtered, and routed by the application.

**Key Characteristics:**
- **Compile-time filtering** - Log statements below the configured level are completely removed at compile time (zero runtime cost)
- **Scoped logging** - Each log message has an associated scope for context and filtering
- **Customizable output** - Applications can override the `logFn` to control formatting and destination
- **Type-safe formatting** - Uses std.fmt-style format strings with compile-time validation
- **Zero dependencies** - Libraries can use std.log without worrying about conflicting logging implementations
- **Build-mode aware** - Default log level automatically adjusts based on build mode (Debug vs ReleaseFast)

**When to use std.log:**
- Application logging for debugging, monitoring, and diagnostics
- Library logging without imposing a specific logging framework on users
- Structured logging where scopes provide filtering and context
- Performance-critical code where compile-time filtering eliminates overhead
- Cross-cutting logging across multiple modules or libraries

**Related namespaces:**
- `std.debug` - Debug utilities (assert, panic, print)
- `std.fmt` - String formatting used by log functions
- `std.Io.Writer` - Output destinations for custom log functions

---

## Log Levels

### `Level` (enum)

```zig
pub const Level = enum {
    err,
    warn,
    info,
    debug,
};
```

Defines the severity/priority of log messages.

**Levels (highest to lowest priority):**
- `.err` - **Error**: Something has gone wrong (may be recoverable or fatal)
- `.warn` - **Warning**: Uncertain if something is wrong, but worth investigating
- `.info` - **Info**: General informational messages about program state
- `.debug` - **Debug**: Detailed information useful only during development/debugging

**Ordering:** `.err` > `.warn` > `.info` > `.debug`

When you set `log_level = .info`, messages at `.info`, `.warn`, and `.err` are logged, but `.debug` messages are filtered out.

---

## Core Logging Functions

### `pub fn debug(comptime format: []const u8, args: anytype) void`

Logs a debug message using the default scope.

**Use when:** Providing detailed information useful only during development (variable values, execution flow, etc.)

**Example:**
```zig
const std = @import("std");

pub fn processData(data: []const u8) void {
    std.log.debug("Processing {d} bytes of data", .{data.len});
    std.log.debug("First byte: 0x{X}", .{data[0]});
}
```

------

### `pub fn info(comptime format: []const u8, args: anytype) void`

Logs an informational message using the default scope.

**Use when:** Reporting general program state (startup, shutdown, major state changes)

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    std.log.info("Application starting...", .{});
    std.log.info("Configuration loaded from {s}", .{config_path});
    std.log.info("Listening on port {d}", .{8080});
}
```

------

### `pub fn warn(comptime format: []const u8, args: anytype) void`

Logs a warning message using the default scope.

**Use when:** Something unexpected happened but the program can continue (deprecated API usage, falling back to defaults, etc.)

**Example:**
```zig
const std = @import("std");

pub fn loadConfig(io: std.Io, path: []const u8) !Config {
    const file = std.Io.Dir.cwd().openFile(io, path, .{}) catch {
  std.log.warn("Config file not found, using defaults", .{});
  return Config.default();
    };
    defer file.close(io);
    // ... load config
}
```

------

### `pub fn err(comptime format: []const u8, args: anytype) void`

Logs an error message using the default scope.

**Use when:** Something has gone wrong (before returning an error, after catching an error, etc.)

**Example:**
```zig
const std = @import("std");

pub fn connectDatabase(url: []const u8) !Database {
    const db = Database.connect(url) catch |e| {
  std.log.err("Failed to connect to database: {s}", .{@errorName(e)});
  return e;
    };
    return db;
}
```

------

## Scoped Logging

### `pub fn scoped(comptime scope: @TypeOf(.enum_literal)) type`

Creates a logging namespace with a custom scope. Returns a struct with the same logging functions (`.debug()`, `.info()`, `.warn()`, `.err()`) that use the provided scope.

**Use when:** You want to distinguish log messages from different modules/libraries

**Example:**
```zig
const std = @import("std");

// Library code
const log = std.log.scoped(.mylib);

pub fn initialize() void {
    log.info("Initializing mylib", .{});
    log.debug("Version: 1.0.0", .{});
}

pub fn shutdown() void {
    log.info("Shutting down mylib", .{});
}

// Output:
// info(mylib): Initializing mylib
// debug(mylib): Version: 1.0.0
// info(mylib): Shutting down mylib
```

**Scope naming conventions:**
- Use lowercase, descriptive names: `.http_server`, `.database`, `.auth`
- For libraries: use the library name: `.libfoo`, `.mypkg`
- For modules: use module name: `.main`, `.parser`, `.renderer`

------

## Utility Functions

### `pub fn logEnabled(comptime level: Level, comptime scope: @TypeOf(.enum_literal)) bool`

Determines if a specific log level and scope combination is enabled for logging.

**Returns:** `true` if logging at the given level/scope is enabled, `false` otherwise

**Use when:** Wrapping expensive computations that are only needed for logging

**Example:**
```zig
const std = @import("std");

pub fn analyzeData(data: []const u8) void {
    // Only compute expensive statistics if debug logging is enabled
    if (std.log.logEnabled(.debug, .default)) {
  const stats = computeExpensiveStatistics(data);
  std.log.debug("Analysis: {any}", .{stats});
    }
}

fn computeExpensiveStatistics(data: []const u8) Stats {
    // Expensive computation here...
}
```

------

## Custom Log Function

### Overriding `logFn`

You can customize logging behavior by providing a custom `logFn` in `std.options`:

```zig
// In root.zig or build.zig configuration
pub const std_options = struct {
    pub fn logFn(
  comptime level: std.log.Level,
  comptime scope: @TypeOf(.enum_literal),
  comptime format: []const u8,
  args: anytype,
    ) void {
  // Your custom implementation
    }
};
```

**Parameters:**
- `level` - Log level (comptime known)
- `scope` - Scope enum literal (comptime known)
- `format` - Format string (comptime known)
- `args` - Tuple of formatting arguments

**Default Implementation:** See `std.log.defaultLog()` which outputs colored text to stderr

------

## Usage Patterns

### Pattern 1: Library with Scoped Logging

```zig
const std = @import("std");

// mylib.zig - A library that uses scoped logging
const log = std.log.scoped(.mylib);

pub const MyLib = struct {
    initialized: bool = false,

    pub fn init() !MyLib {
  log.info("Initializing library", .{});
  log.debug("Performing initialization checks", .{});

  // ... initialization logic

  log.info("Library initialized successfully", .{});
  return MyLib{ .initialized = true };
    }

    pub fn process(self: *MyLib, data: []const u8) !void {
  if (!self.initialized) {
      log.err("Attempted to process data before initialization", .{});
      return error.NotInitialized;
  }

  log.debug("Processing {d} bytes", .{data.len});

  // ... processing logic

  log.info("Processed data successfully", .{});
    }

    pub fn deinit(self: *MyLib) void {
  log.info("Shutting down library", .{});
  self.initialized = false;
    }
};
```

------

### Pattern 2: Application with Custom Log Levels per Scope

```zig
const std = @import("std");

pub const std_options = struct {
    // Global log level
    pub const log_level: std.log.Level = .info;

    // Per-scope log levels
    pub const log_scope_levels = &[_]std.log.ScopeLevel{
  .{ .scope = .http, .level = .debug },     // HTTP module gets debug logs
  .{ .scope = .database, .level = .warn },  // Database only warns/errors
  .{ .scope = .auth, .level = .info },      // Auth gets info and above
    };
};

const http_log = std.log.scoped(.http);
const db_log = std.log.scoped(.database);
const auth_log = std.log.scoped(.auth);

pub fn main() void {
    http_log.debug("This appears", .{});     // Level: debug (enabled for .http)
    db_log.debug("This is hidden", .{});     // Level: debug (filtered for .database)
    db_log.warn("This appears", .{});        // Level: warn (enabled for .database)
    auth_log.info("This appears", .{});      // Level: info (enabled for .auth)
}
```

------

### Pattern 3: Custom Log Function for File Output

```zig
const std = @import("std");

var log_file: ?std.Io.File = null;
var log_mutex: std.Thread.Mutex = .{};

pub const std_options = struct {
    pub fn logFn(
  comptime level: std.log.Level,
  comptime scope: @TypeOf(.enum_literal),
  comptime format: []const u8,
  args: anytype,
    ) void {
  // Thread-safe file logging
  log_mutex.lock();
  defer log_mutex.unlock();

  if (log_file) |file| {
      var buffer: [4096]u8 = undefined;
      var writer = std.Io.Writer.fixed(&buffer);

      // Format: [LEVEL] scope: message
      writer.print("[{s}] {s}: ", .{ @tagName(level), @tagName(scope) }) catch return;
      writer.print(format, args) catch return;
      writer.writeAll("\n") catch return;
      writer.flush() catch return;

      const msg = writer.buffered();
      _ = file.writeAll(std.Io.getStdIo(), msg) catch {};
  }
    }
};

pub fn main() !void {
    const io = std.Io.getStdIo();

    // Open log file
    log_file = try std.Io.Dir.cwd(io).createFile("app.log", .{});
    defer if (log_file) |f| f.close(io);

    std.log.info("Application started", .{});
    std.log.debug("Debug info: {d}", .{42});
    std.log.warn("Warning message", .{});
}
```

------

### Pattern 4: Conditional Logging for Performance

```zig
const std = @import("std");

pub fn processLargeDataset(items: []const Item) !void {
    std.log.info("Processing {d} items", .{items.len});

    for (items, 0..) |item, i| {
  // Expensive operation
  try processItem(item);

  // Only log progress if debug is enabled
  if (std.log.logEnabled(.debug, .default)) {
      if (i % 1000 == 0) {
          std.log.debug("Processed {d}/{d} items", .{ i, items.len });
      }
  }
    }

    std.log.info("Completed processing {d} items", .{items.len});
}

fn processItem(item: Item) !void {
    // Avoid expensive formatting if logging is disabled
    if (std.log.logEnabled(.debug, .default)) {
  const item_info = try formatItemInfo(item);  // Expensive
  defer item_info.deinit();
  std.log.debug("Processing item: {s}", .{item_info.slice()});
    }

    // Actual processing logic...
}
```

------

### Pattern 5: Error Handling with Logging

```zig
const std = @import("std");

pub fn loadAndParseConfig(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Config {
    std.log.debug("Loading config from: {s}", .{path});

    const contents = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024)) catch |err| {
  std.log.err("Failed to read config file: {s}", .{@errorName(err)});
  return err;
    };
    defer allocator.free(contents);

    const config = parseConfig(contents) catch |err| {
  std.log.err("Failed to parse config: {s}", .{@errorName(err)});
  std.log.warn("Falling back to default configuration", .{});
  return Config.default();
    };

    std.log.info("Config loaded successfully from '{s}'", .{path});
    return config;
}
```

------

## Types and Constants

### User-Facing Types

**`Level` (enum)**
```zig
pub const Level = enum {
    err,
    warn,
    info,
    debug,
};
```
Severity levels for log messages. See [Log Levels](#log-levels) section above.

------

**`ScopeLevel` (struct)**
```zig
pub const ScopeLevel = struct {
    scope: @TypeOf(.enum_literal),
    level: Level,
};
```
Maps a specific scope to a log level, allowing per-scope level configuration.

**Example:**
```zig
pub const std_options = struct {
    pub const log_scope_levels = &[_]std.log.ScopeLevel{
  .{ .scope = .network, .level = .debug },
  .{ .scope = .parser, .level = .warn },
    };
};
```

------

### Constants

**`default_level: Level`**
Default log level based on build mode:
- **Debug** builds: `.debug` (all messages)
- **ReleaseSafe** builds: `.info`
- **ReleaseFast** / **ReleaseSmall** builds: `.info`

Can be overridden via `std_options.log_level`.

------

**`default_log_scope: @TypeOf(.enum_literal)`**
The default scope used by `std.log.debug()`, `std.log.info()`, etc.

Value: `.default`

------

## Functions Reference

### Default Log Implementation

**`pub fn defaultLog(comptime level: Level, comptime scope: @TypeOf(.enum_literal), comptime format: []const u8, args: anytype) void`**

The default log function implementation. Outputs to stderr with color support (if terminal).

**Output format:**
```
level: message
level(scope): message
```

**Colors (when supported):**
- `.err` - Red
- `.warn` - Yellow
- `.info` - Default
- `.debug` - Default

**Example:**
```
error: Failed to connect
error(database): Connection timeout
warning: Using default config
info: Server started
debug: Variable x = 42
```

------

## Error Sets

std.log functions do not return errors - they are designed to never fail. If the underlying output fails (e.g., stderr write fails), the error is silently ignored.

------

## Debug Checklist

✅ **Format strings are comptime known** - Cannot use runtime strings as format strings

✅ **Wrap expensive computations in logEnabled() checks** - Prevent waste when logging is disabled

✅ **Use appropriate log levels** - `.err` for errors, `.warn` for concerns, `.info` for state, `.debug` for details

✅ **Scope your library logs** - Use `std.log.scoped(.yourlib)` in libraries

✅ **Don't log sensitive data** - Passwords, API keys, PII should never be logged

✅ **Set appropriate log_level in production** - Usually `.info` or `.warn` to reduce noise

✅ **Custom logFn must handle all levels** - Your implementation should handle all four log levels

✅ **Thread safety in custom logFn** - If logging from multiple threads, use mutex or atomic operations

✅ **Flush output in custom logFn** - Ensure messages appear immediately, not buffered indefinitely

✅ **Check if logging is enabled before format args** - Use `logEnabled()` before expensive argument expressions

------

## Performance Tips

1. **Compile-time elimination is automatic** - Messages below `log_level` are completely removed at compile time (zero cost):
   ```zig
   // If log_level = .info, this entire line disappears at compile time
   std.log.debug("Expensive: {s}", .{veryExpensiveFunction()});
   ```

2. **Guard expensive argument evaluation** - Even if the log statement is cheap, argument evaluation might not be:
   ```zig
   // Bad: formatComplexObject() runs even if debug is disabled
   std.log.debug("Object: {s}", .{formatComplexObject(obj)});

   // Good: only runs formatComplexObject() if debug is enabled
   if (std.log.logEnabled(.debug, .default)) {
 std.log.debug("Object: {s}", .{formatComplexObject(obj)});
   }
   ```

3. **Use scoped logging for granular control** - Enable debug logs only for specific modules:
   ```zig
   pub const std_options = struct {
 pub const log_level = .info;  // Global: info
 pub const log_scope_levels = &[_]std.log.ScopeLevel{
     .{ .scope = .problematic_module, .level = .debug },  // This module: debug
 };
   };
   ```

4. **Avoid allocations in log messages** - Keep format arguments simple:
   ```zig
   // Bad: allocates string just for logging
   const msg = try std.fmt.allocPrint(allocator, "Value: {d}", .{x});
   defer allocator.free(msg);
   std.log.info("{s}", .{msg});

   // Good: direct formatting
   std.log.info("Value: {d}", .{x});
   ```

5. **Batch log output in custom logFn** - If writing to file/network, buffer multiple log messages:
   ```zig
   pub fn logFn(...) void {
 // Buffer multiple messages, flush periodically
 buffer.append(formatted_message);
 if (buffer.len > threshold) {
     flush_to_destination(buffer);
 }
   }
   ```

6. **Profile your logging overhead** - In performance-critical code, measure impact:
   ```zig
   const start = std.time.nanoTimestamp();
   // ... code with logging ...
   const elapsed = std.time.nanoTimestamp() - start;
   ```

7. **Consider structured logging for analysis** - In custom `logFn`, emit JSON for easy parsing:
   ```zig
   pub fn logFn(...) void {
 // {"level":"info","scope":"app","msg":"Server started","timestamp":1234567890}
 writeJsonLogEntry(level, scope, format, args);
   }
   ```

------

## See Also

- **std.debug** - Debug utilities (print, assert, panic)
- **std.fmt** - String formatting used internally by log functions
- **std.Io.Writer** - Writer interface for custom log output
- **std.testing** - Test framework with logging support
- **std.options** - Build configuration (log_level, logFn)
