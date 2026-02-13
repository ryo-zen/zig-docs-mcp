# std.Build

📚 **Core API for build.zig scripts** - The `std.Build` type is the heart of Zig's build system, providing the interface for defining compilation targets, dependencies, and build steps.

## Quick Start

**Basic Executable**
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
  .name = "myapp",
  .root_source_file = b.path("src/main.zig"),
  .target = target,
  .optimize = optimize,
    });

    b.installArtifact(exe);
}
```

**Executable with Dependencies**
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
  .name = "myapp",
  .root_source_file = b.path("src/main.zig"),
  .target = target,
  .optimize = optimize,
    });

    // Add external dependency
    const dep = b.dependency("some_package", .{
  .target = target,
  .optimize = optimize,
    });
    exe.root_module.addImport("pkg", dep.module("pkg"));

    b.installArtifact(exe);
}
```

**Library with Tests**
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build library
    const lib = b.addLibrary(.{
  .name = "mylib",
  .root_source_file = b.path("src/lib.zig"),
  .target = target,
  .optimize = optimize,
    });
    b.installArtifact(lib);

    // Build tests
    const tests = b.addTest(.{
  .root_source_file = b.path("src/lib.zig"),
  .target = target,
  .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
```

**Custom Build Step**
```zig
pub fn build(b: *std.Build) void {
    const gen_step = b.step("gen", "Generate code");

    const gen_cmd = b.addSystemCommand(&.{
  "python3",
  "scripts/codegen.py",
    });
    gen_step.dependOn(&gen_cmd.step);
}
```

---

## Overview

`std.Build` is the primary interface for Zig's build system. Every `build.zig` file receives a `*std.Build` parameter (conventionally named `b`) that provides methods for:

- **Creating build artifacts** - Executables, libraries, objects
- **Managing dependencies** - External packages and modules
- **Defining build steps** - Custom commands and operations
- **Configuring targets** - Cross-compilation and optimization
- **Installing artifacts** - Output files to installation directory

The Build object encapsulates the build configuration, manages the dependency graph, handles user options, and coordinates the execution of build steps.

**Key Characteristics:**
- **Declarative API** - Describe what to build, not how to build it
- **Lazy evaluation** - Build steps are defined but not executed during configuration
- **Dependency tracking** - Automatic rebuild detection based on inputs/outputs
- **Cross-compilation** - First-class support for all Zig targets
- **Caching** - Incremental builds with content-addressable cache

**When to use:**
- Every Zig project with a `build.zig` file uses `std.Build`
- Required for projects with dependencies from package managers
- Essential for cross-platform builds
- Necessary for projects with custom build steps

---

## Core Concepts

### Build Graph
The build system constructs a directed acyclic graph (DAG) of steps. Each step declares its dependencies, and the build runner executes them in topological order. The `graph` field holds shared state across all Build instances.

### Build Steps
Steps represent units of work (compilation, tests, file operations). Common step types:
- `Step.Compile` - Compile Zig code to executable/library
- `Step.Run` - Execute a program
- `Step.WriteFile` - Generate files
- `Step.InstallArtifact` - Copy artifacts to output

### Lazy Paths
`LazyPath` represents a file path that may not exist yet during configuration. Useful for generated files or dependency outputs.

### Modules
Modules are importable Zig source trees. Use `addModule()` to expose modules to other packages, or `createModule()` for internal use only.

---

## Essential Fields

`allocator: Allocator`

The allocator for build-time allocations. All memory allocated during configuration should use this allocator. The build runner manages this memory.

------

`install_prefix: []const u8`

The installation prefix directory (typically `zig-out` or user-specified). Artifacts are installed relative to this path.

------

`build_root: Cache.Directory`

Path to the directory containing `build.zig`. Use `b.path()` to reference files relative to this directory.

------

`cache_root: Cache.Directory`

The global Zig cache directory. Build artifacts and incremental state are stored here for reuse across builds.

---

## Target and Optimization Functions

### `pub fn standardTargetOptions(b: *Build, args: StandardTargetOptionsArgs) ResolvedTarget`

Creates a resolved target from command-line options. Exposes `-Dtarget=<triple>` flag to users for cross-compilation.

**Parameters:**
- `args: StandardTargetOptionsArgs` - Configuration (usually empty `.{}`)

**Returns:** A `ResolvedTarget` that can be passed to `addExecutable()`, `addLibrary()`, etc.

**Example:**
```zig
const target = b.standardTargetOptions(.{});

const exe = b.addExecutable(.{
    .name = "myapp",
    .root_source_file = b.path("src/main.zig"),
    .target = target, // Use the resolved target
    .optimize = optimize,
});
```

------

### `pub fn standardOptimizeOption(b: *Build, options: StandardOptimizeOptionOptions) std.builtin.OptimizeMode`

Creates an optimization mode from command-line options. Exposes `-Doptimize=<mode>` flag with choices: `Debug`, `ReleaseSafe`, `ReleaseFast`, `ReleaseSmall`.

**Returns:** The selected `OptimizeMode`.

**Example:**
```zig
const optimize = b.standardOptimizeOption(.{});
// User can now run: zig build -Doptimize=ReleaseFast
```

---

## Artifact Creation Functions

### `pub fn addExecutable(b: *Build, options: ExecutableOptions) *Step.Compile`

Creates a step to build an executable binary.

**Parameters:**
- `options.name: []const u8` - Executable name (output filename)
- `options.root_source_file: LazyPath` - Path to main source file
- `options.target: ResolvedTarget` - Compilation target
- `options.optimize: OptimizeMode` - Optimization level

**Returns:** A `*Step.Compile` that can be further configured or installed.

**Example:**
```zig
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

// Add dependencies
exe.root_module.addImport("lib", lib_module);

// Install to output
b.installArtifact(exe);
```

------

### `pub fn addLibrary(b: *Build, options: LibraryOptions) *Step.Compile`

Creates a step to build a library (static or dynamic).

**Parameters:**
- `options.name: []const u8` - Library name
- `options.root_source_file: LazyPath` - Path to main source file
- `options.target: ResolvedTarget` - Compilation target
- `options.optimize: OptimizeMode` - Optimization level

**Example:**
```zig
const lib = b.addLibrary(.{
    .name = "mylib",
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});

b.installArtifact(lib);
```

------

### `pub fn addTest(b: *Build, options: TestOptions) *Step.Compile`

Creates a test executable containing unit tests from the specified source file.

**Example:**
```zig
const tests = b.addTest(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

const run_tests = b.addRunArtifact(tests);

const test_step = b.step("test", "Run unit tests");
test_step.dependOn(&run_tests.step);
```

---

## Module and Dependency Functions

### `pub fn addModule(b: *Build, name: []const u8, options: Module.CreateOptions) *Module`

Creates a public module that other packages can import. The module is added to the package's module set and exposed to dependents.

**Parameters:**
- `name: []const u8` - Module name (used in `@import()`)
- `options: Module.CreateOptions` - Module configuration (source file, dependencies)

**Example:**
```zig
const my_module = b.addModule("mylib", .{
    .root_source_file = b.path("src/lib.zig"),
});

// Dependent packages can now: const mylib = @import("mylib");
```

------

### `pub fn dependency(b: *Build, name: []const u8, args: anytype) *Dependency`

Retrieves a dependency by name from `build.zig.zon`. The dependency's `build.zig` is executed with the provided arguments.

**Parameters:**
- `name: []const u8` - Dependency name from `build.zig.zon`
- `args: anytype` - Struct of options passed to dependency's build function

**Returns:** A `*Dependency` with methods to access the dependency's modules and artifacts.

**Example:**
```zig
const dep = b.dependency("httpz", .{
    .target = target,
    .optimize = optimize,
});

// Import the dependency's module
exe.root_module.addImport("httpz", dep.module("httpz"));
```

------

### `pub fn path(b: *Build, sub_path: []const u8) LazyPath`

Creates a `LazyPath` referencing a file relative to the build root (directory containing `build.zig`).

**Example:**
```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

---

## Step Creation Functions

### `pub fn step(b: *Build, name: []const u8, description: []const u8) *Step`

Creates a custom named step that can be invoked with `zig build <name>`.

**Parameters:**
- `name: []const u8` - Step name (command-line argument)
- `description: []const u8` - Help text shown in `zig build --help`

**Example:**
```zig
const docs_step = b.step("docs", "Generate documentation");

const gen_docs = b.addSystemCommand(&.{
    "python3", "scripts/gen_docs.py",
});

docs_step.dependOn(&gen_docs.step);
// User can run: zig build docs
```

------

### `pub fn addRunArtifact(b: *Build, exe: *Step.Compile) *Step.Run`

Creates a step to run an executable artifact. Useful for tests or code generation.

**Example:**
```zig
const exe = b.addExecutable(.{ /* ... */ });
const run_exe = b.addRunArtifact(exe);

const run_step = b.step("run", "Run the application");
run_step.dependOn(&run_exe.step);
```

------

### `pub fn addSystemCommand(b: *Build, argv: []const []const u8) *Step.Run`

Creates a step to run a system command (not a Zig-built executable).

**Parameters:**
- `argv: []const []const u8` - Command and arguments

**Example:**
```zig
const format = b.addSystemCommand(&.{
    "zig", "fmt", "src/",
});

const fmt_step = b.step("fmt", "Format source code");
fmt_step.dependOn(&format.step);
```

---

## Installation Functions

### `pub fn installArtifact(b: *Build, artifact: *Step.Compile) void`

Installs a compiled artifact to the output directory using default options. The artifact is added as a dependency of the top-level install step.

**Example:**
```zig
const exe = b.addExecutable(.{ /* ... */ });
b.installArtifact(exe);
// Executable installed to zig-out/bin/
```

------

### `pub fn getInstallStep(b: *Build) *Step`

Returns the top-level install step. All artifacts installed with `installArtifact()` depend on this step.

**Example:**
```zig
const exe = b.addExecutable(.{ /* ... */ });
const install_exe = b.addInstallArtifact(exe, .{});

b.getInstallStep().dependOn(&install_exe.step);
```

---

## Option Handling Functions

### `pub fn option(b: *Build, comptime T: type, name_raw: []const u8, description_raw: []const u8) ?T`

Creates a user-configurable build option. Users set options with `-D<name>=<value>`.

**Parameters:**
- `T: type` - Option type (bool, []const u8, enum, etc.)
- `name_raw: []const u8` - Option name
- `description_raw: []const u8` - Help text

**Returns:** `?T` - The user-provided value, or `null` if not specified.

**Example:**
```zig
const enable_feature = b.option(bool, "enable_feature", "Enable experimental feature") orelse false;
const log_level = b.option([]const u8, "log_level", "Logging level") orelse "info";

// User can run: zig build -Denable_feature=true -Dlog_level=debug
```

---

## File and Directory Functions

### `pub fn addWriteFiles(b: *Build) *Step.WriteFile`

Creates a step for generating multiple files. Useful for code generation.

**Example:**
```zig
const gen = b.addWriteFiles();
gen.addFile("config.txt", "setting=value\n");
gen.addFile("version.txt", "1.0.0\n");

const config_file = gen.getOutput("config.txt");
// Use config_file as a LazyPath in other steps
```

------

### `pub fn fmt(b: *Build, comptime format: []const u8, args: anytype) []u8`

Formats a string using the build allocator (similar to `std.fmt.allocPrint`).

**Example:**
```zig
const version = "1.0.0";
const app_name = b.fmt("myapp-{s}", .{version});
// Result: "myapp-1.0.0"
```

------

### `pub fn pathJoin(b: *Build, paths: []const []const u8) []u8`

Joins path components using the build allocator.

**Example:**
```zig
const full_path = b.pathJoin(&.{ "src", "components", "ui.zig" });
// Result: "src/components/ui.zig"
```

---

## Usage Patterns

### Pattern 1: Multi-Target Build

```zig
pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // Build for multiple targets
    const targets = [_]std.Target.Query{
  .{ .cpu_arch = .x86_64, .os_tag = .linux },
  .{ .cpu_arch = .aarch64, .os_tag = .macos },
  .{ .cpu_arch = .wasm32, .os_tag = .wasi },
    };

    for (targets) |target_query| {
  const target = b.resolveTargetQuery(target_query);
  const exe = b.addExecutable(.{
      .name = b.fmt("myapp-{s}-{s}", .{
          @tagName(target_query.cpu_arch.?),
          @tagName(target_query.os_tag.?),
      }),
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = optimize,
  });
  b.installArtifact(exe);
    }
}
```

### Pattern 2: Conditional Compilation

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_tls = b.option(bool, "tls", "Enable TLS support") orelse true;

    const exe = b.addExecutable(.{
  .name = "myapp",
  .root_source_file = b.path("src/main.zig"),
  .target = target,
  .optimize = optimize,
    });

    if (enable_tls) {
  const tls_dep = b.dependency("tls", .{
      .target = target,
      .optimize = optimize,
  });
  exe.root_module.addImport("tls", tls_dep.module("tls"));
    }

    b.installArtifact(exe);
}
```

### Pattern 3: Code Generation Step

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Generate code
    const gen = b.addWriteFiles();
    const generated_file = gen.addFile("generated.zig",
  \\pub const VERSION = "1.0.0";
  \\pub const BUILD_DATE = "2026-02-04";
    );

    const exe = b.addExecutable(.{
  .name = "myapp",
  .root_source_file = b.path("src/main.zig"),
  .target = target,
  .optimize = optimize,
    });

    // Add generated file as anonymous module
    exe.root_module.addAnonymousImport("build_info", .{
  .root_source_file = generated_file,
    });

    b.installArtifact(exe);
}
```

### Pattern 4: Test Organization

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Unit tests
    const unit_tests = b.addTest(.{
  .root_source_file = b.path("src/lib.zig"),
  .target = target,
  .optimize = optimize,
    });

    // Integration tests
    const integration_tests = b.addTest(.{
  .root_source_file = b.path("tests/integration.zig"),
  .target = target,
  .optimize = optimize,
    });

    const run_unit = b.addRunArtifact(unit_tests);
    const run_integration = b.addRunArtifact(integration_tests);

    // Separate steps
    const unit_step = b.step("test:unit", "Run unit tests");
    unit_step.dependOn(&run_unit.step);

    const integration_step = b.step("test:integration", "Run integration tests");
    integration_step.dependOn(&run_integration.step);

    // Combined test step
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_unit.step);
    test_step.dependOn(&run_integration.step);
}
```

---

## Common Nested Types

- **`ExecutableOptions`** - Options for `addExecutable()`
- **`LibraryOptions`** - Options for `addLibrary()`
- **`TestOptions`** - Options for `addTest()`
- **`Step`** - Base type for all build steps
- **`Step.Compile`** - Compilation step (executable, library, test)
- **`Step.Run`** - Step to run an executable
- **`Step.WriteFile`** - Step to generate files
- **`Step.InstallArtifact`** - Step to install compiled artifacts
- **`Module`** - Importable Zig source tree
- **`Dependency`** - External package dependency
- **`LazyPath`** - Path that may not exist during configuration
- **`ResolvedTarget`** - Fully resolved compilation target

---

## Debug Checklist

✅ **Use b.path() for local files** - Always use `b.path("src/main.zig")` instead of bare strings for source files.

✅ **Pass target and optimize to dependencies** - Dependencies need the same target and optimization level.

✅ **Remember installArtifact()** - Compiled artifacts won't appear in output without installation.

✅ **Check dependency names** - Names in `dependency()` must match `build.zig.zon` exactly.

✅ **Use step() for custom commands** - Named steps allow users to run `zig build <name>`.

✅ **Don't perform I/O in build()** - The build function configures the graph, actual work happens later.

✅ **Use option() for user configuration** - Avoid hardcoding values that users might want to change.

✅ **Test cross-compilation** - Use `zig build -Dtarget=<triple>` to test different platforms.

---

## Performance Tips

1. **Minimize dependencies** - Each dependency adds build time. Only include what you need.

2. **Use lazy evaluation** - Don't compute values until they're needed. LazyPath and option defaults support this.

3. **Leverage caching** - Zig's cache is content-addressable. Unchanged inputs skip rebuilds automatically.

4. **Parallelize builds** - Independent steps run concurrently. Avoid unnecessary dependencies.

5. **Profile build time** - Use `zig build --verbose` to see which steps take longest.

---

## See Also

- **`std.Build.Step`** - Base type for all build steps
- **`std.Build.Step.Compile`** - Compilation step details
- **`std.Build.Module`** - Module system for code organization
- **`std.Target`** - Cross-compilation target specification
- **`std.builtin.OptimizeMode`** - Optimization level options
