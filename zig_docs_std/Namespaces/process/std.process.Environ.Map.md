# std.process.Environ.Map

### Fields

    array_hash_map: ArrayHashMap

    allocator: Allocator

## Types

- Size

## Namespaces

- EnvNameHashContext

## Functions

`pub fn clone(m: *const Map, gpa: Allocator) Allocator.Error!Map`  
Returns a full copy of `em` allocated with `gpa`, which is not necessarily the same allocator used to allocate `em`.

`pub fn contains(m: *const Map, key: []const u8) bool`  
On Windows, asserts that `key` is valid WTF-8.

`pub fn count(self: Map) Size`  
Returns the number of KV pairs stored in the map.

`pub fn createPosixBlock( map: *const Map, gpa: Allocator, options: CreatePosixBlockOptions, ) Allocator.Error!PosixBlock`  
Creates a null-delimited environment variable block in the format expected by POSIX, from a hash map plus options.

`pub fn createWindowsBlock( map: *const Map, gpa: Allocator, options: CreateWindowsBlockOptions, ) error{ OutOfMemory, InvalidWtf8 }!WindowsBlock`  
Caller owns result.

`pub fn deinit(self: *Map) void`  
Free the backing storage of the map, as well as all of the stored keys and values.

`pub fn get(self: Map, key: []const u8) ?[]const u8`  
Return the map's copy of the value associated with a key. The returned string is invalidated if this key is removed from the map. On Windows, asserts that `key` is valid WTF-8.

`pub fn getPtr(self: Map, key: []const u8) ?*[]const u8`  
Find the address of the value associated with a key. The returned pointer is invalidated if the map resizes. On Windows, asserts that `key` is valid WTF-8.

`pub fn init(allocator: Allocator) Map`  
Create a Map backed by a specific allocator. That allocator will be used for both backing allocations and string deduplication.

`pub fn iterator(self: *const Map) ArrayHashMap.Iterator`  
Returns an iterator over entries in the map.

`pub fn keys(map: *const Map) [][]const u8`  

`pub fn orderedRemove(self: *Map, key: []const u8) bool`  
If there is an entry with a matching key, it is deleted from the map. The entry is removed from the underlying array by shifting all elements forward, thereby maintaining the current ordering.

`pub fn put(self: *Map, key: []const u8, value: []const u8) Allocator.Error!void`  
`key` and `value` are copied into the Map.

`pub fn putMove(self: *Map, key: []u8, value: []u8) Allocator.Error!void`  
Same as `put` but the key and value become owned by the Map rather than being copied. If `putMove` fails, the ownership of key and value does not transfer.

`pub fn putPosixBlock(map: *Map, view: PosixBlock.View) Allocator.Error!void`  

`pub fn putWindowsBlock(map: *Map, view: WindowsBlock.View) Allocator.Error!void`  

`pub fn swapRemove(self: *Map, key: []const u8) bool`  
If there is an entry with a matching key, it is deleted from the hash map. The entry is removed from the underlying array by swapping it with the last element.

`pub fn validateKeyForFetch(key: []const u8) bool`  

`pub fn validateKeyForPut(key: []const u8) bool`  

`pub fn values(map: *const Map) [][]const u8`  
