# std.Io.IoUring

### Fields

    gpa: Allocator

Must be a thread-safe allocator.

    mutex: std.Thread.Mutex

    main_fiber_buffer: [@sizeOf(Fiber) + Fiber.max_result_size]u8 align(@alignOf(Fiber))

    threads: Thread.List

## Functions

`pub fn deinit(el: *EventLoop) void`  

`pub fn init(el: *EventLoop, gpa: Allocator) !void`  

`pub fn io(el: *EventLoop) Io`  
