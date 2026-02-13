# std.Io.Queue

Many producer, many consumer, thread-safe, runtime configurable buffer size. When buffer is empty, consumers suspend and are resumed by producers. When buffer is full, producers suspend and are resumed by consumers.

## Parameters

    Elem: type

### Fields

    type_erased: TypeErasedQueue

## Functions

`pub fn capacity(q: *const @This()) usize`
Returns buffer length in `Elem` units.

`pub fn close(q: *@This(), io: Io) void`

`pub fn get(q: *@This(), io: Io, buffer: []Elem, target: usize) (QueueClosedError || Cancelable)!usize`
Receives elements from the beginning of the queue, potentially blocking if there are insufficient elements currently in the queue. Returns when any one of the following conditions is satisfied:

`pub fn getOne(q: *@This(), io: Io) (QueueClosedError || Cancelable)!Elem`
Receives one element from the beginning of the queue, blocking if the queue is empty.

`pub fn getOneUncancelable(q: *@This(), io: Io) QueueClosedError!Elem`
Same as `getOne`, except does not introduce a cancelation point.

`pub fn getUncancelable(q: *@This(), io: Io, buffer: []Elem, min: usize) QueueClosedError!usize`
Same as `get`, except does not introduce a cancelation point.

`pub fn init(buffer: []Elem) @This()`

`pub fn put(q: *@This(), io: Io, elements: []const Elem, target: usize) (QueueClosedError || Cancelable)!usize`
Appends elements to the end of the queue, potentially blocking if there is insufficient capacity. Returns when any one of the following conditions is satisfied:

`pub fn putAll(q: *@This(), io: Io, elements: []const Elem) (QueueClosedError || Cancelable)!void`
Same as `put` but blocks until all elements have been added to the queue.

`pub fn putOne(q: *@This(), io: Io, item: Elem) (QueueClosedError || Cancelable)!void`
Appends `item` to the end of the queue, blocking if the queue is full.

`pub fn putOneUncancelable(q: *@This(), io: Io, item: Elem) QueueClosedError!void`
Same as `putOne`, except does not introduce a cancelation point.

`pub fn putUncancelable(q: *@This(), io: Io, elements: []const Elem, min: usize) QueueClosedError!usize`
Same as `put`, except does not introduce a cancelation point.
