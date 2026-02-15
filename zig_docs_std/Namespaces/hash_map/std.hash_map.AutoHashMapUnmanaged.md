# std.hash_map.AutoHashMapUnmanaged

## Parameters

    K: type

    V: type

### Fields

    metadata: ?[*]Metadata = null

Pointer to the metadata.

    size: Size = 0

Current number of elements in the hashmap.

    available: Size = 0

Number of available slots before a grow is needed to satisfy the `max_load_percentage`.

    pointer_stability: std.debug.SafetyLock = .{}

Used to detect memory safety violations.

## Types

- Entry
- GetOrPutResult
- Hash
- Iterator
- KV
- KeyIterator
- Managed
- Size
- ValueIterator

## Values

|       |        |                                     |
|-------|--------|-------------------------------------|
| empty | `Self` | A map containing no keys or values. |

## Functions

`pub fn capacity(self: Self) Size`  

`pub fn clearAndFree(self: *Self, allocator: Allocator) void`  

`pub fn clearRetainingCapacity(self: *Self) void`  

`pub fn clone(self: Self, allocator: Allocator) Allocator.Error!Self`  

`pub fn cloneContext(self: Self, allocator: Allocator, new_ctx: anytype) Allocator.Error!HashMapUnmanaged(K, V, @TypeOf(new_ctx), max_load_percentage)`  

`pub fn contains(self: Self, key: K) bool`  
Return true if there is a value associated with key in the map.

`pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`  

`pub fn containsContext(self: Self, key: K, ctx: Context) bool`  

`pub fn count(self: Self) Size`  

`pub fn deinit(self: *Self, allocator: Allocator) void`  

`pub fn ensureTotalCapacity(self: *Self, allocator: Allocator, new_size: Size) Allocator.Error!void`  

`pub fn ensureTotalCapacityContext(self: *Self, allocator: Allocator, new_size: Size, ctx: Context) Allocator.Error!void`  

`pub fn ensureUnusedCapacity(self: *Self, allocator: Allocator, additional_size: Size) Allocator.Error!void`  

`pub fn ensureUnusedCapacityContext(self: *Self, allocator: Allocator, additional_size: Size, ctx: Context) Allocator.Error!void`  

`pub fn fetchPut(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any.

`pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`  
Inserts a new `Entry` into the hash map, returning the previous one, if any. If insertion happens, asserts there is enough capacity without allocating.

`pub fn fetchPutAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) ?KV`  

`pub fn fetchPutContext(self: *Self, allocator: Allocator, key: K, value: V, ctx: Context) Allocator.Error!?KV`  

`pub fn fetchRemove(self: *Self, key: K) ?KV`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and then returned from this function.

`pub fn fetchRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`  

`pub fn fetchRemoveContext(self: *Self, key: K, ctx: Context) ?KV`  

`pub fn get(self: Self, key: K) ?V`  
Get a copy of the value associated with key, if present.

`pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`  

`pub fn getContext(self: Self, key: K, ctx: Context) ?V`  

`pub fn getEntry(self: Self, key: K) ?Entry`  

`pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`  

`pub fn getEntryContext(self: Self, key: K, ctx: Context) ?Entry`  

`pub fn getKey(self: Self, key: K) ?K`  
Get a copy of the actual key associated with adapted key, if present.

`pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`  

`pub fn getKeyContext(self: Self, key: K, ctx: Context) ?K`  

`pub fn getKeyPtr(self: Self, key: K) ?*K`  
Get an optional pointer to the actual key associated with adapted key, if present.

`pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`  

`pub fn getKeyPtrContext(self: Self, key: K, ctx: Context) ?*K`  

`pub fn getOrPut(self: *Self, allocator: Allocator, key: K) Allocator.Error!GetOrPutResult`  

`pub fn getOrPutAdapted(self: *Self, allocator: Allocator, key: anytype, key_ctx: anytype) Allocator.Error!GetOrPutResult`  

`pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`  

`pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`  

`pub fn getOrPutAssumeCapacityContext(self: *Self, key: K, ctx: Context) GetOrPutResult`  

`pub fn getOrPutContext(self: *Self, allocator: Allocator, key: K, ctx: Context) Allocator.Error!GetOrPutResult`  

`pub fn getOrPutContextAdapted(self: *Self, allocator: Allocator, key: anytype, key_ctx: anytype, ctx: Context) Allocator.Error!GetOrPutResult`  

`pub fn getOrPutValue(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!Entry`  

`pub fn getOrPutValueContext(self: *Self, allocator: Allocator, key: K, value: V, ctx: Context) Allocator.Error!Entry`  

`pub fn getPtr(self: Self, key: K) ?*V`  
Get an optional pointer to the value associated with key, if present.

`pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`  

`pub fn getPtrContext(self: Self, key: K, ctx: Context) ?*V`  

`pub fn iterator(self: *const Self) Iterator`  

`pub fn keyIterator(self: Self) KeyIterator`  

`pub fn lockPointers(self: *Self) void`  
Puts the hash map into a state where any method call that would cause an existing key or value pointer to become invalidated will instead trigger an assertion.

`pub fn move(self: *Self) Self`  
Set the map to an empty state, making deinitialization a no-op, and returning a copy of the original.

`pub fn promote(self: Self, allocator: Allocator) Managed`  

`pub fn promoteContext(self: Self, allocator: Allocator, ctx: Context) Managed`  

`pub fn put(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!void`  
Insert an entry if the associated key is not already present, otherwise update preexisting value.

`pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`  
Asserts there is enough capacity to store the new key-value pair. Clobbers any existing data. To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.

`pub fn putAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) void`  

`pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`  
Insert an entry in the map. Assumes it is not already present, and that no allocation is needed.

`pub fn putAssumeCapacityNoClobberContext(self: *Self, key: K, value: V, ctx: Context) void`  

`pub fn putContext(self: *Self, allocator: Allocator, key: K, value: V, ctx: Context) Allocator.Error!void`  

`pub fn putNoClobber(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!void`  
Insert an entry in the map. Assumes it is not already present.

`pub fn putNoClobberContext(self: *Self, allocator: Allocator, key: K, value: V, ctx: Context) Allocator.Error!void`  

`pub fn rehash(self: *Self, ctx: anytype) void`  
Rehash the map, in-place.

`pub fn remove(self: *Self, key: K) bool`  
If there is an `Entry` with a matching key, it is deleted from the hash map, and this function returns true. Otherwise this function returns false.

`pub fn removeAdapted(self: *Self, key: anytype, ctx: anytype) bool`  
TODO: answer the question in these doc comments, does this increase the unused capacity by one?

`pub fn removeByPtr(self: *Self, key_ptr: *K) void`  
Delete the entry with key pointed to by key_ptr from the hash map. key_ptr is assumed to be a valid pointer to a key that is present in the hash map.

`pub fn removeContext(self: *Self, key: K, ctx: Context) bool`  
TODO: answer the question in these doc comments, does this increase the unused capacity by one?

`pub fn unlockPointers(self: *Self) void`  
Undoes a call to `lockPointers`.

`pub fn valueIterator(self: Self) ValueIterator`  
