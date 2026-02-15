# std.hash_map.HashMap

General purpose hash table. No order is guaranteed and any modification invalidates live iterators. It provides fast operations (lookup, insertion, deletion) with quite high load factors (up to 80% by default) for low memory usage. For a hash map that can be initialized directly that does not store an Allocator field, see `HashMapUnmanaged`. If iterating over the table entries is a strong usecase and needs to be fast, prefer the alternative `std.ArrayHashMap`. Context must be a struct type with two member functions: hash(self, K) u64 eql(self, K, K) bool Adapted variants of many functions are provided. These variants take a pseudo key instead of a key. Their context must have the functions: hash(self, PseudoKey) u64 eql(self, PseudoKey, K) bool

## Parameters

    K: type

    V: type

    Context: type

    max_load_percentage: u64

### Fields

    unmanaged: Unmanaged

    allocator: Allocator

    ctx: Context

## Types

- Unmanaged

## Values

|  |  |  |
|----|----|----|
| Entry |  | An entry, containing pointers to a key and value stored in the map |
| GetOrPutResult |  | The type returned from getOrPut and variants |
| Hash |  | The integer type that is the result of hashing |
| Iterator |  | The iterator type returned by iterator() |
| KV |  | A copy of a key and value which are no longer in the map |
| KeyIterator |  |  |
| Size |  | The integer type used to store the size of the map |
| ValueIterator |  |  |

## Functions

`pub fn capacity(self: Self) Size`  
Returns the number of total elements which may be present before it is no longer guaranteed that no allocations will be performed.

`pub fn clearAndFree(self: *Self) void`  
Empty the map and release the backing allocation. This does *not* free keys or values! Be sure to release them if they need deinitialization before calling this function.

`pub fn clearRetainingCapacity(self: *Self) void`  
Empty the map, but keep the backing allocation for future use. This does *not* free keys or values! Be sure to release them if they need deinitialization before calling this function.

`pub fn clone(self: Self) Allocator.Error!Self`  
Creates a copy of this map, using the same allocator

`pub fn cloneWithAllocator(self: Self, new_allocator: Allocator) Allocator.Error!Self`  
Creates a copy of this map, using a specified allocator

`pub fn cloneWithAllocatorAndContext( self: Self, new_allocator: Allocator, new_ctx: anytype, ) Allocator.Error!HashMap(K, V, @TypeOf(new_ctx), max_load_percentage)`  
Creates a copy of this map, using a specified allocator and context.

`pub fn cloneWithContext(self: Self, new_ctx: anytype) Allocator.Error!HashMap(K, V, @TypeOf(new_ctx), max_load_percentage)`  
Creates a copy of this map, using a specified context

`pub fn contains(self: Self, key: K) bool`  
Check if the map contains a key

`pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`  

`pub fn count(self: Self) Size`  
Return the number of items in the map.

`pub fn deinit(self: *Self) void`  
Release the backing array and invalidate this map. This does *not* deinit keys, values, or the context! If your keys or values need to be released, ensure that that is done before calling this function.

`pub fn ensureTotalCapacity(self: *Self, expected_count: Size) Allocator.Error!void`  
Increases capacity, guaranteeing that insertions up until the `expected_count` will not cause an allocation, and therefore cannot fail.

`pub fn ensureUnusedCapacity(self: *Self, additional_count: Size) Allocator.Error!void`  
Increases capacity, guaranteeing that insertions up until `additional_count` **more** items will not cause an allocation, and therefore cannot fail.

`pub fn fetchPut(self: *Self, key: K, value: V) Allocator.Error!?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any.

`pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any. If insertion happens, asserts there is enough capacity without allocating.

`pub fn fetchRemove(self: *Self, key: K) ?KV`  
Removes a value from the map and returns the removed kv pair.

`pub fn fetchRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn get(self: Self, key: K) ?V`  
Finds the value associated with a key in the map

`pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`  

`pub fn getEntry(self: Self, key: K) ?Entry`  
Finds the key and value associated with a key in the map

`pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`  

`pub fn getKey(self: Self, key: K) ?K`  
Finds the actual key associated with an adapted key in the map

`pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`  

`pub fn getKeyPtr(self: Self, key: K) ?*K`  

`pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`  

`pub fn getOrPut(self: *Self, key: K) Allocator.Error!GetOrPutResult`  
If key exists this function cannot fail. If there is an existing item with `key`, then the result's `Entry` pointers point to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointers point to it. Caller should then initialize the value (but not the key).

`pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) Allocator.Error!GetOrPutResult`  
If key exists this function cannot fail. If there is an existing item with `key`, then the result's `Entry` pointers point to it, and found_existing is true. Otherwise, puts a new item with undefined key and value, and the `Entry` pointers point to it. Caller must then initialize the key and value.

`pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`  
If there is an existing item with `key`, then the result's `Entry` pointers point to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointers point to it. Caller should then initialize the value (but not the key). If a new entry needs to be stored, this function asserts there is enough capacity to store it.

`pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`  
If there is an existing item with `key`, then the result's `Entry` pointers point to it, and found_existing is true. Otherwise, puts a new item with undefined value, and the `Entry` pointers point to it. Caller must then initialize the key and value. If a new entry needs to be stored, this function asserts there is enough capacity to store it.

`pub fn getOrPutValue(self: *Self, key: K, value: V) Allocator.Error!Entry`  

`pub fn getPtr(self: Self, key: K) ?*V`  

`pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`  

`pub fn init(allocator: Allocator) Self`  
Create a managed hash map with an empty context. If the context is not zero-sized, you must use initContext(allocator, ctx) instead.

`pub fn initContext(allocator: Allocator, ctx: Context) Self`  
Create a managed hash map with a context

`pub fn iterator(self: *const Self) Iterator`  
Create an iterator over the entries in the map. The iterator is invalidated if the map is modified.

`pub fn keyIterator(self: Self) KeyIterator`  
Create an iterator over the keys in the map. The iterator is invalidated if the map is modified.

`pub fn lockPointers(self: *Self) void`  
Puts the hash map into a state where any method call that would cause an existing key or value pointer to become invalidated will instead trigger an assertion.

`pub fn move(self: *Self) Self`  
Set the map to an empty state, making deinitialization a no-op, and returning a copy of the original.

`pub fn put(self: *Self, key: K, value: V) Allocator.Error!void`  
Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPut`.

`pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Asserts that it does not clobber any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putNoClobber(self: *Self, key: K, value: V) Allocator.Error!void`  
Inserts a key-value pair into the hash map, asserting that no previous entry with the same key is already present

`pub fn rehash(self: *Self) void`  
Rehash the map, in-place.

`pub fn remove(self: *Self, key: K) bool`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and this function returns true. Otherwise this function returns false.

`pub fn removeAdapted(self: *Self, key: anytype, ctx: anytype) bool`  
TODO: answer the question in these doc comments, does this increase the unused capacity by one?

`pub fn removeByPtr(self: *Self, key_ptr: *K) void`  
Delete the entry with key pointed to by key_ptr from the hash map. key_ptr is assumed to be a valid pointer to a key that is present in the hash map.

`pub fn unlockPointers(self: *Self) void`  
Undoes a call to `lockPointers`.

`pub fn valueIterator(self: Self) ValueIterator`  
Create an iterator over the values in the map. The iterator is invalidated if the map is modified.
