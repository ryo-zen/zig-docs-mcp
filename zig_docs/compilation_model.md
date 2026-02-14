# Compilation Model

Zig compilation is organized as a graph of modules and discovered declarations.
Understanding this model helps prevent missing tests, missing exports, and unintended build behavior.

## Overview

A module is a set of Zig files with one root source file. Modules depend on other modules and import them by module name.

In most programs:

- Your code is the root module.
- `@import("std")` is available through the standard library module.
- `@import("root")` refers to your root module's root source file.

## Runnable Examples

- `zig_docs_std/Examples/build_release_modes.tests.zig`
- `zig_docs_std/Examples/testing.tests.zig`

## Quick Start

1. Define module boundaries intentionally.
2. Keep imports explicit so needed declarations are discovered.
3. Force discovery for critical `test`/`export` files when required.
4. Keep target and optimize settings explicit in `build.zig`.

## [Source File Structs](#toc-Source-File-Structs) §

Every Zig source file behaves like an implicit `struct` container.
That is why top-level declarations and fields coexist naturally.

TopLevelFields.zig
```zig
//! Because this file contains fields, it represents an instantiable type.

foo: u32,
bar: u64,

const TopLevelFields = @This();

pub fn init(val: u32) TopLevelFields {
    return .{
        .foo = val,
        .bar = val * 10,
    };
}
```

A file's root struct type can be referenced from inside the same file using `@This()`.

## [File and Declaration Discovery](#toc-File-and-Declaration-Discovery) §

Zig analyzes code based on discovery rules. In practice:

1. If an analyzed declaration calls `@import`, the imported file can be discovered.
2. If a type/file is analyzed, its `comptime` and `export` declarations are analyzed.
3. In `zig test` for the root module, `test` declarations in discovered files are analyzed.
4. Referencing a declaration causes that declaration to be analyzed (order-independent).

Compilation roots begin in the standard library startup path, which eventually reaches your root module via `@import("root")`.

When you must guarantee discovery of specific files, import them from discovered `comptime` or `test` blocks:

force_file_discovery.zig
```zig
const builtin = @import("builtin");

comptime {
    _ = @import("api.zig");
    if (builtin.os.tag == .windows) {
        _ = @import("windows_api.zig");
    }
}

test {
    _ = @import("tests.zig");
    if (builtin.os.tag == .windows) {
        _ = @import("windows_tests.zig");
    }
}
```

## [Special Root Declarations](#toc-Special-Root-Declarations) §

Some declarations in the root module are consumed by the standard library runtime.

### [Entry Point](#toc-Entry-Point) §

For executables, the main entry point is usually `pub fn main(...)`.

`std.start` invokes it after runtime setup. Defining `_start` can bypass default startup logic when low-level control is needed.

entry_point.zig
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, World!\n", .{});
}

// Uncommenting this disables default std.start behavior.
// pub const _start = {};
```

Shell$ `zig build-exe entry_point.zig`

If linking libc, `main` may also be provided as a C ABI export:

libc_export_entry_point.zig
```zig
const std = @import("std");

pub export fn main(argc: c_int, argv: [*]const [*:0]const u8) c_int {
    const args = argv[0..@intCast(argc)];
    std.debug.print("Hello! argv[0] is '{s}'\n", .{args[0]});
    return 0;
}
```

### [Standard Library Options](#toc-Standard-Library-Options) §

`pub const std_options: std.Options = ...` in the root module can customize standard library behavior (for example logging and segfault handling).

std_options.zig
```zig
const std = @import("std");

pub const std_options: std.Options = .{
    .enable_segfault_handler = true,
    .logFn = myLogFn,
};

fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    std.log.defaultLog(level, scope, format, args);
}
```

### [Panic Handler](#toc-Panic-Handler) §

The root module can provide `panic` to control panic output/behavior.

Use `std.debug.FullPanic(...)` when you want custom output while keeping structured panic formatting.

panic_handler.zig
```zig
const std = @import("std");

pub fn main() void {
    @setRuntimeSafety(true);
    var x: u8 = 255;
    x += 1;
}

pub const panic = std.debug.FullPanic(myPanic);

fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    std.debug.print("Panic! {s}\n", .{msg});
    std.process.exit(1);
}
```

## Decision Guide

- Use one module when the codebase is small and ownership is clear.
- Split modules when API boundaries or team ownership become distinct.
- Force declaration discovery when missing tests/exports would be high risk.
- Prefer explicit root declarations for runtime behavior that must be deterministic.

## Gotchas

1. Files not imported into the discovery graph are not analyzed.
2. Assuming test discovery without explicit imports can hide missing coverage.
3. Overusing root-level global declarations can couple unrelated components.
4. Implicit host target/build defaults in `build.zig` reduce reproducibility.

## Related Docs

- [Build Mode](build_mode.md)
- [Targets](targets.md)
- [Comptime](comptime.md)
- [Zig Build System](zig_build_system.md)
