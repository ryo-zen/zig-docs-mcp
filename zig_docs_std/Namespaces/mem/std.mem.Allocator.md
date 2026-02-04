# std.mem.Allocator

The standard memory allocation interface.

### Fields

    ptr: *anyopaque

The type erased pointer to the allocator implementation.

Any comparison of this field may result in illegal behavior, since it may be set to `undefined` in cases where the allocator implementation does not have any associated state.

    vtable: *const VTable

## Types

- Log2Align
- VTable

## Values

|         |             |                                             |
|---------|-------------|---------------------------------------------|
| failing | `Allocator` | An allocator that always fails to allocate. |

## Functions

`pub fn alignedAlloc( self: Allocator, comptime T: type, comptime alignment: ?Alignment, n: usize, ) Error![]align(if (alignment) |a| a.toByteUnits() else @alignOf(T)) T`  

`pub fn alloc(self: Allocator, comptime T: type, n: usize) Error![]T`  
Allocates an array of `n` items of type `T` and sets all the items to `undefined`. Depending on the Allocator implementation, it may be required to call `free` once the memory is no longer needed, to avoid a resource leak. If the `Allocator` implementation is unknown, then correct code will call `free` when done.

`pub inline fn allocAdvancedWithRetAddr( self: Allocator, comptime T: type, comptime alignment: ?Alignment, n: usize, return_address: usize, ) Error![]align(if (alignment) |a| a.toByteUnits() else @alignOf(T)) T`  

`pub fn allocSentinel( self: Allocator, comptime Elem: type, n: usize, comptime sentinel: Elem, ) Error![:sentinel]Elem`  
Allocates an array of `n + 1` items of type `T` and sets the first `n` items to `undefined` and the last item to `sentinel`. Depending on the Allocator implementation, it may be required to call `free` once the memory is no longer needed, to avoid a resource leak. If the `Allocator` implementation is unknown, then correct code will call `free` when done.

`pub fn allocWithOptions( self: Allocator, comptime Elem: type, n: usize, comptime optional_alignment: ?Alignment, comptime optional_sentinel: ?Elem, ) Error!AllocWithOptionsPayload(Elem, optional_alignment, optional_sentinel)`  

`pub fn allocWithOptionsRetAddr( self: Allocator, comptime Elem: type, n: usize, comptime optional_alignment: ?Alignment, comptime optional_sentinel: ?Elem, return_address: usize, ) Error!AllocWithOptionsPayload(Elem, optional_alignment, optional_sentinel)`  

`pub fn create(a: Allocator, comptime T: type) Error!*T`  
Returns a pointer to undefined memory. Call `destroy` with the result to free the memory.

`pub fn destroy(self: Allocator, ptr: anytype) void`  
`ptr` should be the return value of `create`, or otherwise have the same address and alignment property.

`pub fn dupe(allocator: Allocator, comptime T: type, m: []const T) Error![]T`  
Copies `m` to newly allocated memory. Caller owns the memory.

`pub fn dupeZ(allocator: Allocator, comptime T: type, m: []const T) Error![:0]T`  
Copies `m` to newly allocated memory, with a null-terminated element. Caller owns the memory.

`pub fn free(self: Allocator, memory: anytype) void`  
Free an array allocated with `alloc`. If memory has length 0, free is a no-op. To free a single item, see `destroy`.

`pub fn noAlloc( self: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize, ) ?[*]u8`  

`pub fn noFree( self: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize, ) void`  

`pub fn noRemap( self: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize, ) ?[*]u8`  

`pub fn noResize( self: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize, ) bool`  

`pub inline fn rawAlloc(a: Allocator, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8`  
This function is not intended to be called except from within the implementation of an `Allocator`.

`pub inline fn rawFree(a: Allocator, memory: []u8, alignment: Alignment, ret_addr: usize) void`  
This function is not intended to be called except from within the implementation of an `Allocator`.

`pub inline fn rawRemap(a: Allocator, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8`  
This function is not intended to be called except from within the implementation of an `Allocator`.

`pub inline fn rawResize(a: Allocator, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool`  
This function is not intended to be called except from within the implementation of an `Allocator`.

`pub fn realloc(self: Allocator, old_mem: anytype, new_n: usize) t: { const Slice = @typeInfo(@TypeOf(old_mem)).pointer; break :t Error![]align(Slice.alignment) Slice.child; }`  
This function requests a new size for an existing allocation, which can be larger, smaller, or the same size as the old memory allocation. The result is an array of `new_n` items of the same type as the existing allocation.

`pub fn reallocAdvanced( self: Allocator, old_mem: anytype, new_n: usize, return_address: usize, ) t: { const Slice = @typeInfo(@TypeOf(old_mem)).pointer; break :t Error![]align(Slice.alignment) Slice.child; }`  

`pub fn remap(self: Allocator, allocation: anytype, new_len: usize) t: { const Slice = @typeInfo(@TypeOf(allocation)).pointer; break :t ?[]align(Slice.alignment) Slice.child; }`  
Request to modify the size of an allocation, allowing relocation.

`pub fn resize(self: Allocator, allocation: anytype, new_len: usize) bool`  
Request to modify the size of an allocation.

## Error Sets

- Error
