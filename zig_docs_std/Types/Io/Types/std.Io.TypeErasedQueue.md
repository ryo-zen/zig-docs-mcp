# std.Io.TypeErasedQueue

### Fields

    mutex: Mutex

    closed: bool

    buffer: []u8

Ring buffer. This data is logically *after* queued getters.

    start: usize

    len: usize

    putters: std.DoublyLinkedList

    getters: std.DoublyLinkedList

## Functions

`pub fn close(q: *TypeErasedQueue, io: Io) void`  

`pub fn get(q: *TypeErasedQueue, io: Io, buffer: []u8, min: usize) (QueueClosedError || Cancelable)!usize`  

`pub fn getUncancelable(q: *TypeErasedQueue, io: Io, buffer: []u8, min: usize) QueueClosedError!usize`  
Same as `get`, except does not introduce a cancelation point.

`pub fn init(buffer: []u8) TypeErasedQueue`  

`pub fn put(q: *TypeErasedQueue, io: Io, elements: []const u8, min: usize) (QueueClosedError || Cancelable)!usize`  

`pub fn putUncancelable(q: *TypeErasedQueue, io: Io, elements: []const u8, min: usize) QueueClosedError!usize`  
Same as `put`, except does not introduce a cancelation point.
