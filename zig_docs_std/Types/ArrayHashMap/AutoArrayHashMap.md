An ArrayHashMap with default hash and equal functions.

See AutoContext for a description of the hash and equal implementations.
Parameters

K: type

V: type

Source Code

pub fn AutoArrayHashMap(comptime K: type, comptime V: type) type {
    return ArrayHashMap(K, V, AutoContext(K), !autoEqlIsCheap(K));
}