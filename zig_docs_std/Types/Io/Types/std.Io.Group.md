# std.Io.Group

An unordered set of tasks which can only be awaited or canceled as a whole. Tasks are spawned in the group with `Group.async` and `Group.concurrent`.

The resources associated with each task are *guaranteed* to be released when the individual task returns, as opposed to when the whole group completes or is awaited. For this reason, it is not a resource leak to have a long-lived group which concurrent tasks are repeatedly added to. However, asynchronous tasks are not guaranteed to run until `Group.await` or `Group.cancel` is called, so adding async tasks to a group without ever awaiting it may leak resources.

### Fields

    token: std.atomic.Value(?*anyopaque)

This value indicates whether or not a group has pending tasks. `null` means there are no pending tasks, and no resources associated with the group, so `await` and `cancel` return immediately without calling the implementation. This means that `token` must be accessed atomically to avoid racing with the check in `await` and `cancel`.

    state: usize

This value is available for the implementation to use as it wishes.

## Values

|      |         |     |
|------|---------|-----|
| init | `Group` |     |

## Functions

`pub fn async(g: *Group, io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function))) void`  
Equivalent to `Io.async`, except the task is spawned in this `Group` instead of becoming associated with a `Future`.

`pub fn await(g: *Group, io: Io) Cancelable!void`  
Blocks until all tasks of the group finish. During this time, cancelation requests propagate to all members of the group, and will also cause `error.Canceled` to be returned when the group does ultimately finish.

`pub fn cancel(g: *Group, io: Io) void`  
Equivalent to `await` but immediately requests cancelation on all members of the group.

`pub fn concurrent(g: *Group, io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function))) ConcurrentError!void`  
Equivalent to `Io.concurrent`, except the task is spawned in this `Group` instead of becoming associated with a `Future`.
