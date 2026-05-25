# std.Io.AnyFuture

Opaque token used by `std.Io` implementations to track an in-flight asynchronous or concurrent task.

Application code normally does not create or inspect this value directly. It is stored inside `std.Io.Future(T)` and passed back to the backend through `std.Io.VTable.await` and `std.Io.VTable.cancel`.

## Source Code

```zig
pub const AnyFuture = opaque {};
```

## Usage

Use `std.Io.Future(T)` as the public handle for task results. `AnyFuture` is the type-erased backend handle behind that future.

## See Also

- `std.Io.Future`
- `std.Io.VTable`
- `std.Io.Group`
- `std.Io.Select`
