# std.Io.Batch

Low-level batch submission helper for `std.Io.Operation` values.

`Batch` submits multiple operations together without waiting for every operation to complete immediately. It is the operation-level API underneath higher-level task tools such as `std.Io.Group` and `std.Io.Select`.

## Initialization

```zig
pub fn init(storage: []Operation.Storage) Batch
```

Creates a batch backed by caller-provided operation storage. The storage length is the maximum number of active operations.

## Functions

```zig
pub fn add(batch: *Batch, operation: Operation) u32
```

Adds an operation and returns the storage index that will be reported when it completes.

```zig
pub fn addAt(batch: *Batch, index: u32, operation: Operation) void
```

Adds an operation at a specific storage index.

```zig
pub fn next(batch: *Batch) ?Completion
```

Returns the next completed operation, or `null` when none are available.

```zig
pub fn awaitAsync(batch: *Batch, io: Io) Cancelable!void
```

Awaits operations through the backend async path.

```zig
pub fn awaitConcurrent(batch: *Batch, io: Io, timeout: Timeout) AwaitConcurrentError!void
```

Awaits operations through the backend concurrent path with timeout support.

```zig
pub fn cancel(batch: *Batch, io: Io) void
```

Cancels pending work owned by the batch.

## See Also

- `std.Io.Operation`
- `std.Io.Group`
- `std.Io.Select`
- `std.Io.Timeout`
