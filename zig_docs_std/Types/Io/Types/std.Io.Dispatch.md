# std.Io.Dispatch

Darwin dispatch-based `std.Io` backend.

`Dispatch` is imported from `Io/Dispatch.zig` and is selected by `std.Io.Evented` on supported Apple platforms. It provides an `std.Io` implementation backed by platform dispatch facilities and shared code from `std.Io.Threaded`.

## Functions

```zig
pub fn init(ev: *Evented, backing_allocator: Allocator, options: InitOptions) !void
```

Initializes the backend with a backing allocator and initialization options.

```zig
pub fn deinit(ev: *Evented) void
```

Releases backend resources.

```zig
pub fn io(ev: *Evented) Io
```

Returns the type-erased `std.Io` interface for this backend.

## See Also

- `std.Io.Evented`
- `std.Io.Kqueue`
- `std.Io.Uring`
- `std.Io.Threaded`
