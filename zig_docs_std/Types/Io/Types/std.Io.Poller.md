# std.Io.Poller

## Parameters

    StreamEnum: type

### Fields

    gpa: Allocator

    readers: [enum_fields.len]Reader

    poll_fds: [enum_fields.len]PollFd

    windows: if (is_windows) struct {
        first_read_done: bool,
        overlapped: [enum_fields.len]windows.OVERLAPPED,
        small_bufs: [enum_fields.len][128]u8,
        active: struct {
            count: math.IntFittingRange(0, enum_fields.len),
            handles_buf: [enum_fields.len]windows.HANDLE,
            stream_map: [enum_fields.len]StreamEnum,

            pub fn removeAt(self: *@This(), index: u32) void {
                assert(index < self.count);
                for (index + 1..self.count) |i| {
                    self.handles_buf[i - 1] = self.handles_buf[i];
                    self.stream_map[i - 1] = self.stream_map[i];
                }
                self.count -= 1;
            }
        },
    } else void

## Functions

`pub fn deinit(self: *Self) void`  

`pub fn poll(self: *Self) !bool`  

`pub fn pollTimeout(self: *Self, nanoseconds: u64) !bool`  

`pub fn reader(self: *Self, which: StreamEnum) *Reader`  

`pub fn removeAt(self: *@This(), index: u32) void`  

`pub fn toOwnedSlice(self: *Self, which: StreamEnum) error{OutOfMemory}![]u8`  
