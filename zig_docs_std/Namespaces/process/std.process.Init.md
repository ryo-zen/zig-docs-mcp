# std.process.Init

A standard set of pre-initialized useful APIs for programs to take advantage of. This is the type of the first parameter of the main function. Applications wanting more flexibility can accept `Init.Minimal` instead.

Completion of https://github.com/ziglang/zig/issues/24510 will also allow the second parameter of the main function to be a custom struct that contain auto-parsed CLI arguments.

### Fields

    minimal: Minimal

`Init` is a superset of `Minimal`; the latter is included here.

    arena: *std.heap.ArenaAllocator

Permanent storage for the entire process, cleaned automatically on exit. Not threadsafe.

    gpa: Allocator

A default-selected general purpose allocator for temporary heap allocations. Debug mode will set up leak checking if possible. Threadsafe.

    io: Io

An appropriate default Io implementation based on the target configuration. Debug mode will set up leak checking if possible.

    environ_map: *Environ.Map

Environment variables, initialized with `gpa`. Not threadsafe.

    preopens: Preopens

Named files that have been provided by the parent process. This is mainly useful on WASI, but can be used on other systems to mimic the behavior with respect to stdio.

## Types

- Minimal
