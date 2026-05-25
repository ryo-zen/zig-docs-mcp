# std.Io.Operation

Low-level operation union used by `std.Io.operate`, `std.Io.operateTimeout`, and `std.Io.Batch`.

Most application code uses higher-level file, directory, networking, future, group, or select APIs. `Operation` is useful when code needs to submit backend operations explicitly and process completions through a `Batch`.

## Union Tags

- `file_read_streaming`
- `file_write_streaming`
- `device_io_control`
- `net_receive`

## Related Types

- `Tag`
- `FileReadStreaming`
- `FileWriteStreaming`
- `DeviceIoControl`
- `NetReceive`
- `Result`
- `Storage`
- `OptionalIndex`
- `List`

## Functions

`Operation` itself is data. The public helpers that consume it are:

```zig
pub fn operate(io: Io, operation: Operation) Cancelable!Operation.Result
```

```zig
pub fn operateTimeout(io: Io, operation: Operation, timeout: Timeout) OperateTimeoutError!Operation.Result
```

## See Also

- `std.Io.Batch`
- `std.Io.Timeout`
- `std.Io.VTable`
