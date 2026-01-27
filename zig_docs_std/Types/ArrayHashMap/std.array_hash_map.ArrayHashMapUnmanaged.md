# std.array_hash_map.ArrayHashMapUnmanaged

A hash table of keys and values, each stored sequentially.

Insertion order is preserved. In general, this data structure supports the same operations as `std.ArrayList`.

Deletion operations:

- `swapRemove` - O(1)
- `orderedRemove` - O(N)

Modifying the hash map while iterating is allowed, however, one must understand the (well defined) behavior when mixing insertions and deletions with iteration.

This type does not store an `Allocator` field - the `Allocator` must be passed in with each function call that requires it. See `ArrayHashMap` for a type that stores an `Allocator` field for convenience.

Can be initialized directly using the default field values.

This type is designed to have low overhead for small numbers of entries. When `store_hash` is `false` and the number of entries in the map is less than 9, the overhead cost of using `ArrayHashMapUnmanaged` rather than `std.ArrayList` is only a single pointer-sized integer.

Default initialization of this struct is deprecated; use `.empty` instead.

## Parameters

    K: type

    V: type

    Context: type

A namespace that provides these two functions:

- `pub fn hash(self, K) u32`
- `pub fn eql(self, K, K, usize) bool`

The final `usize` in the `eql` function represents the index of the key that's already inside the map.

    store_hash: bool

When `false`, this data structure is biased towards cheap `eql` functions and avoids storing each key's hash in the table. Setting `store_hash` to `true` incurs more memory cost but limits `eql` to being called only once per insertion/deletion (provided there are no hash collisions).

### Fields

    entries: DataList = .{}

It is permitted to access this field directly. After any modification to the keys, consider calling `reIndex`.

    index_header: ?*IndexHeader = null

When entries length is less than `linear_scan_max`, this remains `null`. Once entries length grows big enough, this field is allocated. There is an IndexHeader followed by an array of Index(I) structs, where I is defined by how many total indexes there are.

    pointer_stability: std.debug.SafetyLock = .{}

Used to detect memory safety violations.

## Types

- Data
- DataList
- Entry
- GetOrPutResult
- Hash
- Iterator
- KV
- Managed

## Values

|       |        |                                     |
|-------|--------|-------------------------------------|
| empty | `Self` | A map containing no keys or values. |

## Functions

`pub fn capacity(self: Self) usize`  
Returns the number of total elements which may be present before it is no longer guaranteed that no allocations will be performed.

`pub fn clearAndFree(self: *Self, gpa: Allocator) void`  
Clears the map and releases the backing allocation

`pub fn clearRetainingCapacity(self: *Self) void`  
Clears the map but retains the backing allocation for future use.

`pub fn clone(self: Self, gpa: Allocator) Oom!Self`  
Create a copy of the hash map which can be modified separately. The copy uses the same context as this instance, but is allocated with the provided allocator.

`pub fn cloneContext(self: Self, gpa: Allocator, ctx: Context) Oom!Self`  

`pub fn contains(self: Self, key: K) bool`  
Check whether a key is stored in the map

`pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`  

`pub fn containsContext(self: Self, key: K, ctx: Context) bool`  

`pub fn count(self: Self) usize`  
Returns the number of KV pairs stored in this map.

`pub fn deinit(self: *Self, gpa: Allocator) void`  
Frees the backing allocation and leaves the map in an undefined state. Note that this does not free keys or values. You must take care of that before calling this function, if it is needed.

`pub fn ensureTotalCapacity(self: *Self, gpa: Allocator, new_capacity: usize) Oom!void`  
Increases capacity, guaranteeing that insertions up until the `expected_count` will not cause an allocation, and therefore cannot fail.

`pub fn ensureTotalCapacityContext(self: *Self, gpa: Allocator, new_capacity: usize, ctx: Context) Oom!void`  

`pub fn ensureUnusedCapacity( self: *Self, gpa: Allocator, additional_capacity: usize, ) Oom!void`  
Increases capacity, guaranteeing that insertions up until `additional_count` **more** items will not cause an allocation, and therefore cannot fail.

`pub fn ensureUnusedCapacityContext( self: *Self, gpa: Allocator, additional_capacity: usize, ctx: Context, ) Oom!void`  

`pub fn fetchOrderedRemove(self: *Self, key: K) ?KV`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and then returned from this function. The entry is removed from the underlying array by shifting all elements forward thereby maintaining the current ordering.

`pub fn fetchOrderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn fetchOrderedRemoveContext(self: *Self, key: K, ctx: Context) ?KV`  

`pub fn fetchOrderedRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) ?KV`  

`pub fn fetchPut(self: *Self, gpa: Allocator, key: K, value: V) Oom!?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any.

`pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any. If insertion happens, asserts there is enough capacity without allocating.

`pub fn fetchPutAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) ?KV`  

`pub fn fetchPutContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!?KV`  

`pub fn fetchSwapRemove(self: *Self, key: K) ?KV`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and then returned from this function. The entry is removed from the underlying array by swapping it with the last element.

`pub fn fetchSwapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn fetchSwapRemoveContext(self: *Self, key: K, ctx: Context) ?KV`  

`pub fn fetchSwapRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) ?KV`  

`pub fn get(self: Self, key: K) ?V`  
Find the value associated with a key

`pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`  

`pub fn getContext(self: Self, key: K, ctx: Context) ?V`  

`pub fn getEntry(self: Self, key: K) ?Entry`  
Finds pointers to the key and value storage associated with a key.

`pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`  

`pub fn getEntryContext(self: Self, key: K, ctx: Context) ?Entry`  

`pub fn getIndex(self: Self, key: K) ?usize`  
Finds the index in the `entries` array where a key is stored

`pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`  

`pub fn getIndexContext(self: Self, key: K, ctx: Context) ?usize`  

`pub fn getKey(self: Self, key: K) ?K`  
Find the actual key associated with an adapted key

`pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`  

`pub fn getKeyContext(self: Self, key: K, ctx: Context) ?K`  

`pub fn getKeyPtr(self: Self, key: K) ?*K`  
Find a pointer to the actual key associated with an adapted key

`pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`  

`pub fn getKeyPtrContext(self: Self, key: K, ctx: Context) ?*K`  

`pub fn getOrPut(self: *Self, gpa: Allocator, key: K) Oom!GetOrPutResult`  
If key exists this function cannot fail. If there is an existing item with `key`, then the result `Entry` pointer points to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointer points to it. Caller should then initialize the value (but not the key).

`pub fn getOrPutAdapted(self: *Self, gpa: Allocator, key: anytype, key_ctx: anytype) Oom!GetOrPutResult`  

`pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`  
If there is an existing item with `key`, then the result `Entry` pointer points to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointer points to it. Caller should then initialize the value (but not the key). If a new entry needs to be stored, this function asserts there is enough capacity to store it.

`pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`  
If there is an existing item with `key`, then the result `Entry` pointers point to it, and found_existing is true. Otherwise, puts a new item with undefined key and value, and the `Entry` pointers point to it. Caller must then initialize both the key and the value. If a new entry needs to be stored, this function asserts there is enough capacity to store it.

`pub fn getOrPutAssumeCapacityContext(self: *Self, key: K, ctx: Context) GetOrPutResult`  

`pub fn getOrPutContext(self: *Self, gpa: Allocator, key: K, ctx: Context) Oom!GetOrPutResult`  

`pub fn getOrPutContextAdapted(self: *Self, gpa: Allocator, key: anytype, key_ctx: anytype, ctx: Context) Oom!GetOrPutResult`  

`pub fn getOrPutValue(self: *Self, gpa: Allocator, key: K, value: V) Oom!GetOrPutResult`  

`pub fn getOrPutValueContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!GetOrPutResult`  

`pub fn getPtr(self: Self, key: K) ?*V`  
Find a pointer to the value associated with a key

`pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`  

`pub fn getPtrContext(self: Self, key: K, ctx: Context) ?*V`  

`pub fn init(gpa: Allocator, key_list: []const K, value_list: []const V) Oom!Self`  

`pub fn iterator(self: Self) Iterator`  
Returns an iterator over the pairs in this map. Modifying the map may invalidate this iterator.

`pub fn keys(self: Self) []K`  
Returns the backing array of keys in this map. Modifying the map may invalidate this array. Modifying this array in a way that changes key hashes or key equality puts the map into an unusable state until `reIndex` is called.

`pub fn lockPointers(self: *Self) void`  
Puts the hash map into a state where any method call that would cause an existing key or value pointer to become invalidated will instead trigger an assertion.

`pub fn move(self: *Self) Self`  
Set the map to an empty state, making deinitialization a no-op, and returning a copy of the original.

`pub fn orderedRemove(self: *Self, key: K) bool`  
If there is an `Entry` with a matching key, it is deleted from the hash map. The entry is removed from the underlying array by shifting all elements forward, thereby maintaining the current ordering. Returns true if an entry was removed, false otherwise.

`pub fn orderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`  

`pub fn orderedRemoveAt(self: *Self, index: usize) void`  
Deletes the item at the specified index in `entries` from the hash map. The entry is removed from the underlying array by shifting all elements forward, thereby maintaining the current ordering.

`pub fn orderedRemoveAtContext(self: *Self, index: usize, ctx: Context) void`  

`pub fn orderedRemoveAtMany(self: *Self, gpa: Allocator, sorted_indexes: []const usize) Oom!void`  
Remove the entries indexed by `sorted_indexes`. The indexes to be removed correspond to state before deletion.

`pub fn orderedRemoveAtManyContext( self: *Self, gpa: Allocator, sorted_indexes: []const usize, ctx: Context, ) Oom!void`  

`pub fn orderedRemoveContext(self: *Self, key: K, ctx: Context) bool`  

`pub fn orderedRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) bool`  

`pub fn pop(self: *Self) ?KV`  
Removes the last inserted `Entry` in the hash map and returns it. Otherwise returns null.

`pub fn popContext(self: *Self, ctx: Context) ?KV`  

`pub fn promote(self: Self, gpa: Allocator) Managed`  
Convert from an unmanaged map to a managed map. After calling this, the promoted map should no longer be used.

`pub fn promoteContext(self: Self, gpa: Allocator, ctx: Context) Managed`  

`pub fn put(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`  
Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPut`.

`pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) void`  

`pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Asserts that it does not clobber any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putAssumeCapacityNoClobberContext(self: *Self, key: K, value: V, ctx: Context) void`  

`pub fn putContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!void`  

`pub fn putNoClobber(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`  
Inserts a key-value pair into the hash map, asserting that no previous entry with the same key is already present

`pub fn putNoClobberContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!void`  

`pub fn reIndex(self: *Self, gpa: Allocator) Oom!void`  
Recomputes stored hashes and rebuilds the key indexes. If the underlying keys have been modified directly, call this method to recompute the denormalized metadata necessary for the operation of the methods of this map that lookup entries by key.

`pub fn reIndexContext(self: *Self, gpa: Allocator, ctx: Context) Oom!void`  

`pub fn reinit(self: *Self, gpa: Allocator, key_list: []const K, value_list: []const V) Oom!void`  
An empty `value_list` may be passed, in which case the values array becomes `undefined`.

`pub fn setKey(self: *Self, gpa: Allocator, index: usize, new_key: K) Oom!void`  
Modify an entry's key without reordering any entries.

`pub fn setKeyContext(self: *Self, gpa: Allocator, index: usize, new_key: K, ctx: Context) Oom!void`  

`pub fn shrinkAndFree(self: *Self, gpa: Allocator, new_len: usize) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Reduces allocated capacity.

`pub fn shrinkAndFreeContext(self: *Self, gpa: Allocator, new_len: usize, ctx: Context) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Reduces allocated capacity.

`pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Keeps capacity the same.

`pub fn shrinkRetainingCapacityContext(self: *Self, new_len: usize, ctx: Context) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Keeps capacity the same.

`pub inline fn sort(self: *Self, sort_ctx: anytype) void`  
Sorts the entries and then rebuilds the index. `sort_ctx` must have this method: `fn lessThan(ctx: @TypeOf(ctx), a_index: usize, b_index: usize) bool` Uses a stable sorting algorithm.

`pub inline fn sortContext(self: *Self, sort_ctx: anytype, ctx: Context) void`  

`pub inline fn sortUnstable(self: *Self, sort_ctx: anytype) void`  
Sorts the entries and then rebuilds the index. `sort_ctx` must have this method: `fn lessThan(ctx: @TypeOf(ctx), a_index: usize, b_index: usize) bool` Uses an unstable sorting algorithm.

`pub inline fn sortUnstableContext(self: *Self, sort_ctx: anytype, ctx: Context) void`  

`pub fn swapRemove(self: *Self, key: K) bool`  
If there is an `Entry` with a matching key, it is deleted from the hash map. The entry is removed from the underlying array by swapping it with the last element. Returns true if an entry was removed, false otherwise.

`pub fn swapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`  

`pub fn swapRemoveAt(self: *Self, index: usize) void`  
Deletes the item at the specified index in `entries` from the hash map. The entry is removed from the underlying array by swapping it with the last element.

`pub fn swapRemoveAtContext(self: *Self, index: usize, ctx: Context) void`  

`pub fn swapRemoveContext(self: *Self, key: K, ctx: Context) bool`  

`pub fn swapRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) bool`  

`pub fn unlockPointers(self: *Self) void`  
Undoes a call to `lockPointers`.

`pub fn values(self: Self) []V`  
Returns the backing array of values in this map. Modifying the map may invalidate this array. It is permitted to modify the values in this array.
