# std.Io.Event

Logical boolean flag which can be set and unset and supports a "wait until set" operation.

### Fields

    unset

    waiting

    is_set

## Functions

`pub fn isSet(event: *const Event) bool`  
Returns whether the logical boolean is `true`.

`pub fn reset(e: *Event) void`  
Sets the logical boolean to false.

`pub fn set(e: *Event, io: Io) void`  
Sets the logical boolean to true, and hence unblocks any pending calls to `wait`. The logical boolean remains true until `reset` is called, so future calls to `set` have no semantic effect.

`pub fn wait(event: *Event, io: Io) Io.Cancelable!void`  
Blocks until the logical boolean is `true`.

`pub fn waitTimeout(event: *Event, io: Io, timeout: Timeout) WaitTimeoutError!void`  
Blocks the calling thread until either the logical boolean is set, the timeout expires, or a spurious wakeup occurs. If the timeout expires or a spurious wakeup occurs, `error.Timeout` is returned.

`pub fn waitUncancelable(event: *Event, io: Io) void`  
Same as `wait`, except does not introduce a cancelation point.

## Error Sets

- WaitTimeoutError
