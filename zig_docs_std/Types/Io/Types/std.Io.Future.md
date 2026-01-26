# std.Io.Future

## Parameters

    Result: type

### Fields

    any_future: ?*AnyFuture

    result: Result

## Functions

`pub fn await(f: *@This(), io: Io) Result`  
Idempotent. Not threadsafe.

`pub fn cancel(f: *@This(), io: Io) Result`  
Equivalent to `await` but places a cancelation request. This causes the task to receive `error.Canceled` from its next "cancelation point" (if any). A cancelation point is a call to a function in `Io` which can return `error.Canceled`.
