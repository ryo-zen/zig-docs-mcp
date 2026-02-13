# Zig Standard Library Documentation Index

This documentation is organized into main categories:

## Types
Direct Zig standard library types and their methods:

### ArrayHashMap
- [ArrayHashMapUnmanaged](Types/ArrayHashMap/std.array_hash_map.ArrayHashMapUnmanaged.md)
- [ArrayHashMapWithAllocator](Types/ArrayHashMap/std.array_hash_map.ArrayHashMapWithAllocator.md)
- [AutoArrayHashMap](Types/ArrayHashMap/std.array_hash_map.AutoArrayHashMap.md)
- [AutoArrayHashMapUnmanaged](Types/ArrayHashMap/std.array_hash_map.AutoArrayHashMapUnmanaged.md)

### ArrayList
- [Aligned](Types/ArrayList/std.array_list.Aligned.md)
- [ArrayList](Types/ArrayList/std.ArrayList.md)

### AutoHashMap
- [AutoHashMap](Types/AutoHashMap/std.hash_map.AutoHashMap.md)
- [AutoHashMapUnmanaged](Types/AutoHashMap/std.hash_map.AutoHashMapUnmanaged.md)

### BitStack
- [BitStack](Types/BitStack/std.BitStack.md) - Memory-efficient stack for u1 values (8 bits per byte)

### BufMap
- [BufMap](Types/BufMap/std.buf_map.BufMap.md) - String-to-string hash map with automatic string ownership

### BufSet
- [BufSet](Types/BufSet/std.buf_set.BufSet.md) - Set of strings with automatic string ownership and deduplication

### Build
- [Build](Types/Build/std.Build.md) - Zig build system API (core build.zig functionality)

### Io
- [std.Io](Types/Io/std.io.md) - **Main Entry Point** (Includes Threaded, Evented, File, Reader, Writer, etc.)
- [std.Io.net](Types/Io/Namespaces/std.Io.net.md) - Networking Module

## Namespaces
Standard library modules:

### mem (std.mem)
- [std.mem Overview](Namespaces/mem/std.mem.md) - Memory manipulation, allocation, and utilities
- [Allocator](Namespaces/mem/std.mem.Allocator.md) - Standard memory allocation interface
- [Alignment](Namespaces/mem/std.mem.Alignment.md) - Memory alignment type and operations
- [SplitIterator](Namespaces/mem/std.mem.SplitIterator.md) - Forward splitting iterator (preserves empty fields)
- [SplitBackwardsIterator](Namespaces/mem/std.mem.SplitBackwardsIterator.md) - Backward splitting iterator
- [TokenIterator](Namespaces/mem/std.mem.TokenIterator.md) - Tokenization iterator (skips empty fields)
- [WindowIterator](Namespaces/mem/std.mem.WindowIterator.md) - Sliding window iterator
- [DelimiterType](Namespaces/mem/std.mem.DelimiterType.md) - Delimiter type enum for iterators
- [ValidationAllocator](Namespaces/mem/std.mem.ValidationAllocator.md) - Allocator wrapper with validation checks

### Net (std.Io.net)
- [Network Overview](Types/Io/Namespaces/std.Io.net.md)
- [IpAddress](Types/Io/Namespaces/std.Io.net.IpAddress.md)
- [Socket](Types/Io/Namespaces/std.Io.net.Socket.md)

## Navigation
Use the MCP server tools to search and explore the documentation:
- `search_zig_docs` - Search across all documentation
- `get_builtin_info` - Get information about builtin functions
- `explain_concept` - Get detailed explanations of language concepts
- `get_syntax_examples` - Get code examples for language constructs
