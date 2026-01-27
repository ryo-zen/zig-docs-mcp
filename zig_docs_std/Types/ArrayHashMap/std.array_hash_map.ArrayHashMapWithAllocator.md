# std.array_hash_map.ArrayHashMapWithAllocator

A hash table of keys and values, each stored sequentially.

Insertion order is preserved. In general, this data structure supports the same operations as `std.ArrayList`.

Deletion operations:

- `swapRemove` - O(1)
- `orderedRemove` - O(N)

Modifying the hash map while iterating is allowed, however, one must understand the (well defined) behavior when mixing insertions and deletions with iteration.

See `ArrayHashMapUnmanaged` for a variant of this data structure that accepts an `Allocator` as a parameter when needed rather than storing it.

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

    unmanaged: Unmanaged

    allocator: Allocator

    ctx: Context

## Types

- Unmanaged

## Values

|  |  |  |
|----|----|----|
| Data |  | The Data type used for the MultiArrayList backing this map |
| DataList |  | The MultiArrayList type backing this map |
| Entry |  | Pointers to a key and value in the backing store of this map. Modifying the key is allowed only if it does not change the hash. Modifying the value is allowed. Entry pointers become invalid whenever this ArrayHashMap is modified, unless `ensureTotalCapacity`/`ensureUnusedCapacity` was previously used. |
| GetOrPutResult |  | getOrPut variants return this structure, with pointers to the backing store and a flag to indicate whether an existing entry was found. Modifying the key is allowed only if it does not change the hash. Modifying the value is allowed. Entry pointers become invalid whenever this ArrayHashMap is modified, unless `ensureTotalCapacity`/`ensureUnusedCapacity` was previously used. |
| Hash |  | The stored hash type, either u32 or void. |
| Iterator |  | An Iterator over Entry pointers. |
| KV |  | A KV pair which has been copied out of the backing store |

## Functions

`pub fn capacity(self: Self) usize`  
Returns the number of total elements which may be present before it is no longer guaranteed that no allocations will be performed.

`pub fn clearAndFree(self: *Self) void`  
Clears the map and releases the backing allocation

`pub fn clearRetainingCapacity(self: *Self) void`  
Clears the map but retains the backing allocation for future use.

`pub fn clone(self: Self) !Self`  
Create a copy of the hash map which can be modified separately. The copy uses the same context and allocator as this instance.

`pub fn cloneWithAllocator(self: Self, allocator: Allocator) !Self`  
Create a copy of the hash map which can be modified separately. The copy uses the same context as this instance, but the specified allocator.

`pub fn cloneWithAllocatorAndContext(self: Self, allocator: Allocator, ctx: anytype) !ArrayHashMap(K, V, @TypeOf(ctx), store_hash)`  
Create a copy of the hash map which can be modified separately. The copy uses the specified allocator and context.

`pub fn cloneWithContext(self: Self, ctx: anytype) !ArrayHashMap(K, V, @TypeOf(ctx), store_hash)`  
Create a copy of the hash map which can be modified separately. The copy uses the same allocator as this instance, but the specified context.

`pub fn contains(self: Self, key: K) bool`  
Check whether a key is stored in the map

`pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`  

`pub fn count(self: Self) usize`  
Returns the number of KV pairs stored in this map.

`pub fn deinit(self: *Self) void`  
Frees the backing allocation and leaves the map in an undefined state. Note that this does not free keys or values. You must take care of that before calling this function, if it is needed.

`pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) !void`  
Increases capacity, guaranteeing that insertions up until the `expected_count` will not cause an allocation, and therefore cannot fail.

`pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) !void`  
Increases capacity, guaranteeing that insertions up until `additional_count` **more** items will not cause an allocation, and therefore cannot fail.

`pub fn fetchOrderedRemove(self: *Self, key: K) ?KV`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and then returned from this function. The entry is removed from the underlying array by shifting all elements forward thereby maintaining the current ordering.

`pub fn fetchOrderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn fetchPut(self: *Self, key: K, value: V) !?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any.

`pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any. If insertion happuns, asserts there is enough capacity without allocating.

`pub fn fetchSwapRemove(self: *Self, key: K) ?KV`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and then returned from this function. The entry is removed from the underlying array by swapping it with the last element.

`pub fn fetchSwapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn get(self: Self, key: K) ?V`  
Find the value associated with a key

`pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`  

`pub fn getEntry(self: Self, key: K) ?Entry`  
Finds pointers to the key and value storage associated with a key.

`pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`  

`pub fn getIndex(self: Self, key: K) ?usize`  
Finds the index in the `entries` array where a key is stored

`pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`  

`pub fn getKey(self: Self, key: K) ?K`  
Find the actual key associated with an adapted key

`pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`  

`pub fn getKeyPtr(self: Self, key: K) ?*K`  
Find a pointer to the actual key associated with an adapted key

`pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`  

`pub fn getOrPut(self: *Self, key: K) !GetOrPutResult`  
If key exists this function cannot fail. If there is an existing item with `key`, then the result `Entry` pointer points to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointer points to it. Caller should then initialize the value (but not the key).

`pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) !GetOrPutResult`  

`pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`  
If there is an existing item with `key`, then the result `Entry` pointer points to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointer points to it. Caller should then initialize the value (but not the key). If a new entry needs to be stored, this function asserts there is enough capacity to store it.

`pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`  

`pub fn getOrPutValue(self: *Self, key: K, value: V) !GetOrPutResult`  

`pub fn getPtr(self: Self, key: K) ?*V`  
Find a pointer to the value associated with a key

`pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`  

`pub fn init(allocator: Allocator) Self`  
Create an ArrayHashMap instance which will use a specified allocator.

`pub fn initContext(allocator: Allocator, ctx: Context) Self`  

`pub fn iterator(self: *const Self) Iterator`  
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

`pub fn pop(self: *Self) ?KV`  
Removes the last inserted `Entry` in the hash map and returns it if count is nonzero. Otherwise returns null.

`pub fn put(self: *Self, key: K, value: V) !void`  
Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPut`.

`pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Asserts that it does not clobber any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putNoClobber(self: *Self, key: K, value: V) !void`  
Inserts a key-value pair into the hash map, asserting that no previous entry with the same key is already present

`pub fn reIndex(self: *Self) !void`  
Recomputes stored hashes and rebuilds the key indexes. If the underlying keys have been modified directly, call this method to recompute the denormalized metadata necessary for the operation of the methods of this map that lookup entries by key.

`pub fn shrinkAndFree(self: *Self, new_len: usize) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Reduces allocated capacity.

`pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`  
Shrinks the underlying `Entry` array to `new_len` elements and discards any associated index entries. Keeps capacity the same.

`pub fn sort(self: *Self, sort_ctx: anytype) void`  
Sorts the entries and then rebuilds the index. `sort_ctx` must have this method: `fn lessThan(ctx: @TypeOf(ctx), a_index: usize, b_index: usize) bool` Uses a stable sorting algorithm.

`pub fn sortUnstable(self: *Self, sort_ctx: anytype) void`  
Sorts the entries and then rebuilds the index. `sort_ctx` must have this method: `fn lessThan(ctx: @TypeOf(ctx), a_index: usize, b_index: usize) bool` Uses an unstable sorting algorithm.

`pub fn swapRemove(self: *Self, key: K) bool`  
If there is an `Entry` with a matching key, it is deleted from the hash map. The entry is removed from the underlying array by swapping it with the last element. Returns true if an entry was removed, false otherwise.

`pub fn swapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`  

`pub fn swapRemoveAt(self: *Self, index: usize) void`  
Deletes the item at the specified index in `entries` from the hash map. The entry is removed from the underlying array by swapping it with the last element.

`pub fn unlockPointers(self: *Self) void`  
Undoes a call to `lockPointers`.

`pub fn values(self: Self) []V`  
Returns the backing array of values in this map. Modifying the map may invalidate this array. It is permitted to modify the values in this array.
