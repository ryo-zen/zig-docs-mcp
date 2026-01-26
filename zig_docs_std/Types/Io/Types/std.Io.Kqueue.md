# std.Io.Kqueue

### Fields

    gpa: Allocator

Must be a thread-safe allocator.

    mutex: std.Thread.Mutex

    main_fiber_buffer: [@sizeOf(Fiber) + Fiber.max_result_size]u8 align(@alignOf(Fiber))

    threads: Thread.List

## Types

- InitOptions

## Functions

`pub fn createFileDescriptor() CreateFileDescriptorError!posix.fd_t`  

`pub fn deinit(k: *Kqueue) void`  

`pub fn init(k: *Kqueue, gpa: Allocator, options: InitOptions) !void`  

`pub fn io(k: *Kqueue) Io`  

`pub fn kevent( kq: i32, changelist: []const posix.Kevent, eventlist: []posix.Kevent, timeout: ?*const posix.timespec, ) KEventError!usize`  

## Error Sets

- CreateFileDescriptorError
- InitError
- KEventError
