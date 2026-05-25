# std.Io.failingNetSend

Default helper used by failing `std.Io` implementations for network send operations.

The function ignores its inputs and reports a failed send with zero messages sent. It is useful as a vtable entry for an `std.Io` backend that does not support network sending.

## Signature

```zig
pub fn failingNetSend(
    userdata: ?*anyopaque,
    handle: net.Socket.Handle,
    messages: []net.OutgoingMessage,
    flags: net.SendFlags,
) struct { ?net.Socket.SendError, usize }
```

## Behavior

Returns:

```zig
.{ error.NetworkDown, 0 }
```

## See Also

- `std.Io.VTable`
- `std.Io.failing`
