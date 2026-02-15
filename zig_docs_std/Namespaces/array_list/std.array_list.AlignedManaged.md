# std.array_list.AlignedManaged

Deprecated.

## Parameters

    T: type

    alignment: ?mem.Alignment

### Fields

    items: Slice

Contents of the list. This field is intended to be accessed directly.

Pointers to elements in this slice are invalidated by various functions of this ArrayList in accordance with the respective documentation. In all cases, "invalidated" means that the memory has been passed to this allocator's resize or free function.

    capacity: usize

How many T values this list can hold without allocating additional memory.

    allocator: Allocator

## Types

- SentinelSlice
- Slice

## Functions

`pub fn addManyAsArray(self: *Self, comptime n: usize) Allocator.Error!*[n]T`  
Resize the array, adding `n` new elements, which have `undefined` values. The return value is an array pointing to the newly allocated elements. The returned pointer becomes invalid when the list is resized. Resizes list if `self.capacity` is not large enough.

`pub fn addManyAsArrayAssumeCapacity(self: *Self, comptime n: usize) *[n]T`  
Resize the array, adding `n` new elements, which have `undefined` values. The return value is an array pointing to the newly allocated elements. Never invalidates element pointers. The returned pointer becomes invalid when the list is resized. Asserts that the list can hold the additional items.

`pub fn addManyAsSlice(self: *Self, n: usize) Allocator.Error![]T`  
Resize the array, adding `n` new elements, which have `undefined` values. The return value is a slice pointing to the newly allocated elements. The returned pointer becomes invalid when the list is resized. Resizes list if `self.capacity` is not large enough.

`pub fn addManyAsSliceAssumeCapacity(self: *Self, n: usize) []T`  
Resize the array, adding `n` new elements, which have `undefined` values. The return value is a slice pointing to the newly allocated elements. Never invalidates element pointers. The returned pointer becomes invalid when the list is resized. Asserts that the list can hold the additional items.

`pub fn addManyAt(self: *Self, index: usize, count: usize) Allocator.Error![]T`  
Add `count` new elements at position `index`, which have `undefined` values. Returns a slice pointing to the newly allocated elements, which becomes invalid after various `ArrayList` operations. Invalidates pre-existing pointers to elements at and after `index`. Invalidates all pre-existing element pointers if capacity must be increased to accommodate the new elements. Asserts that the index is in bounds or equal to the length.

`pub fn addManyAtAssumeCapacity(self: *Self, index: usize, count: usize) []T`  
Add `count` new elements at position `index`, which have `undefined` values. Returns a slice pointing to the newly allocated elements, which becomes invalid after various `ArrayList` operations. Asserts that there is enough capacity for the new elements. Invalidates pre-existing pointers to elements at and after `index`, but does not invalidate any before that. Asserts that the index is in bounds or equal to the length.

`pub fn addOne(self: *Self) Allocator.Error!*T`  
Increase length by 1, returning pointer to the new item. The returned pointer becomes invalid when the list resized.

`pub fn addOneAssumeCapacity(self: *Self) *T`  
Increase length by 1, returning pointer to the new item. The returned pointer becomes invalid when the list is resized. Never invalidates element pointers. Asserts that the list can hold one additional item.

`pub fn allocatedSlice(self: Self) Slice`  
Returns a slice of all the items plus the extra capacity, whose memory contents are `undefined`.

`pub fn append(self: *Self, item: T) Allocator.Error!void`  
Extends the list by 1 element. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed.

`pub fn appendAssumeCapacity(self: *Self, item: T) void`  
Extends the list by 1 element. Never invalidates element pointers. Asserts that the list can hold one additional item.

`pub inline fn appendNTimes(self: *Self, value: T, n: usize) Allocator.Error!void`  
Append a value to the list `n` times. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed. The function is inline so that a comptime-known `value` parameter will have a more optimal memset codegen in case it has a repeated byte pattern.

`pub inline fn appendNTimesAssumeCapacity(self: *Self, value: T, n: usize) void`  
Append a value to the list `n` times. Never invalidates element pointers. The function is inline so that a comptime-known `value` parameter will have a more optimal memset codegen in case it has a repeated byte pattern. Asserts that the list can hold the additional items.

`pub fn appendSlice(self: *Self, items: []const T) Allocator.Error!void`  
Append the slice of items to the list. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed.

`pub fn appendSliceAssumeCapacity(self: *Self, items: []const T) void`  
Append the slice of items to the list. Never invalidates element pointers. Asserts that the list can hold the additional items.

`pub fn appendUnalignedSlice(self: *Self, items: []align(1) const T) Allocator.Error!void`  
Append an unaligned slice of items to the list. Allocates more memory as necessary. Only call this function if calling `appendSlice` instead would be a compile error. Invalidates element pointers if additional memory is needed.

`pub fn appendUnalignedSliceAssumeCapacity(self: *Self, items: []align(1) const T) void`  
Append the slice of items to the list. Never invalidates element pointers. This function is only needed when calling `appendSliceAssumeCapacity` instead would be a compile error due to the alignment of the `items` parameter. Asserts that the list can hold the additional items.

`pub fn clearAndFree(self: *Self) void`  
Invalidates all element pointers.

`pub fn clearRetainingCapacity(self: *Self) void`  
Reduce length to 0. Invalidates all element pointers.

`pub fn clone(self: Self) Allocator.Error!Self`  
Creates a copy of this ArrayList, using the same allocator.

`pub fn deinit(self: Self) void`  
Release all allocated memory.

`pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) Allocator.Error!void`  
If the current capacity is less than `new_capacity`, this function will modify the array so that it can hold at least `new_capacity` items. Invalidates element pointers if additional memory is needed.

`pub fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) Allocator.Error!void`  
If the current capacity is less than `new_capacity`, this function will modify the array so that it can hold exactly `new_capacity` items. Invalidates element pointers if additional memory is needed.

`pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) Allocator.Error!void`  
Modify the array so that it can hold at least `additional_count` **more** items. Invalidates element pointers if additional memory is needed.

`pub fn expandToCapacity(self: *Self) void`  
Increases the array's length to match the full capacity that is already allocated. The new elements have `undefined` values. Never invalidates element pointers.

`pub fn fromOwnedSlice(gpa: Allocator, slice: Slice) Self`  
ArrayList takes ownership of the passed in slice. The slice must have been allocated with `gpa`. Deinitialize with `deinit` or use `toOwnedSlice`.

`pub fn fromOwnedSliceSentinel(gpa: Allocator, comptime sentinel: T, slice: [:sentinel]T) Self`  
ArrayList takes ownership of the passed in slice. The slice must have been allocated with `gpa`. Deinitialize with `deinit` or use `toOwnedSlice`.

`pub fn getLast(self: Self) T`  
Returns the last element from the list. Asserts that the list is not empty.

`pub fn getLastOrNull(self: Self) ?T`  
Returns the last element from the list, or `null` if list is empty.

`pub fn init(gpa: Allocator) Self`  
Deinitialize with `deinit` or use `toOwnedSlice`.

`pub fn initCapacity(gpa: Allocator, num: usize) Allocator.Error!Self`  
Initialize with capacity to hold `num` elements. The resulting capacity will equal `num` exactly. Deinitialize with `deinit` or use `toOwnedSlice`.

`pub fn insert(self: *Self, i: usize, item: T) Allocator.Error!void`  
Insert `item` at index `i`. Moves `list[i .. list.len]` to higher indices to make room. If `i` is equal to the length of the list this operation is equivalent to append. This operation is O(N). Invalidates element pointers if additional memory is needed. Asserts that the index is in bounds or equal to the length.

`pub fn insertAssumeCapacity(self: *Self, i: usize, item: T) void`  
Insert `item` at index `i`. Moves `list[i .. list.len]` to higher indices to make room. If `i` is equal to the length of the list this operation is equivalent to appendAssumeCapacity. This operation is O(N). Asserts that there is enough capacity for the new item. Asserts that the index is in bounds or equal to the length.

`pub fn insertSlice( self: *Self, index: usize, items: []const T, ) Allocator.Error!void`  
Insert slice `items` at index `i` by moving `list[i .. list.len]` to make room. This operation is O(N). Invalidates pre-existing pointers to elements at and after `index`. Invalidates all pre-existing element pointers if capacity must be increased to accommodate the new elements. Asserts that the index is in bounds or equal to the length.

`pub fn moveToUnmanaged(self: *Self) Aligned(T, alignment)`  
Initializes an ArrayList with the `items` and `capacity` fields of this ArrayList. Empties this ArrayList.

`pub fn orderedRemove(self: *Self, i: usize) T`  
Remove the element at index `i`, shift elements after index `i` forward, and return the removed element. Invalidates element pointers to end of list. This operation is O(N). This preserves item order. Use `swapRemove` if order preservation is not important. Asserts that the index is in bounds. Asserts that the list is not empty.

`pub fn pop(self: *Self) ?T`  
Remove and return the last element from the list, or return `null` if list is empty. Invalidates element pointers to the removed element, if any.

`pub fn print(self: *Self, comptime fmt: []const u8, args: anytype) error{OutOfMemory}!void`  

`pub fn replaceRange(self: *Self, start: usize, len: usize, new_items: []const T) Allocator.Error!void`  
Grows or shrinks the list as necessary. Invalidates element pointers if additional capacity is allocated. Asserts that the range is in bounds.

`pub fn replaceRangeAssumeCapacity(self: *Self, start: usize, len: usize, new_items: []const T) void`  
Grows or shrinks the list as necessary. Never invalidates element pointers. Asserts the capacity is enough for additional items.

`pub fn resize(self: *Self, new_len: usize) Allocator.Error!void`  
Adjust the list length to `new_len`. Additional elements contain the value `undefined`. Invalidates element pointers if additional memory is needed.

`pub fn shrinkAndFree(self: *Self, new_len: usize) void`  
Reduce allocated capacity to `new_len`. May invalidate element pointers. Asserts that the new length is less than or equal to the previous length.

`pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`  
Reduce length to `new_len`. Invalidates element pointers for the elements `items[new_len..]`. Asserts that the new length is less than or equal to the previous length.

`pub fn swapRemove(self: *Self, i: usize) T`  
Removes the element at the specified index and returns it. The empty slot is filled from the end of the list. This operation is O(1). This may not preserve item order. Use `orderedRemove` if you need to preserve order. Asserts that the index is in bounds.

`pub fn toOwnedSlice(self: *Self) Allocator.Error!Slice`  
The caller owns the returned memory. Empties this ArrayList. Its capacity is cleared, making `deinit` safe but unnecessary to call.

`pub fn toOwnedSliceSentinel(self: *Self, comptime sentinel: T) Allocator.Error!SentinelSlice(sentinel)`  
The caller owns the returned memory. Empties this ArrayList.

`pub fn unusedCapacitySlice(self: Self) []T`  
Returns a slice of only the extra capacity after items. This can be useful for writing directly into an ArrayList. Note that such an operation must be followed up with a direct modification of `self.items.len`.
