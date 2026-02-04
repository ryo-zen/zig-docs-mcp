# std.mem.ValidationAllocator

Detects and asserts if the std.mem.Allocator interface is violated by the caller or the allocator.

## Parameters

    T: type

### Fields

    underlying_allocator: T

## Functions

`pub fn alloc( ctx: *anyopaque, n: usize, alignment: mem.Alignment, ret_addr: usize, ) ?[*]u8`  

`pub fn allocator(self: *Self) Allocator`  

`pub fn free( ctx: *anyopaque, buf: []u8, alignment: Alignment, ret_addr: usize, ) void`  

`pub fn init(underlying_allocator: T) @This()`  

`pub fn remap( ctx: *anyopaque, buf: []u8, alignment: Alignment, new_len: usize, ret_addr: usize, ) ?[*]u8`  

`pub fn reset(self: *Self) void`  

`pub fn resize( ctx: *anyopaque, buf: []u8, alignment: Alignment, new_len: usize, ret_addr: usize, ) bool`  
