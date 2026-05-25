# std.Treap

`std.Treap` is the root alias for the `Treap` type factory in `treap.zig`.

## Source Declaration

```zig
pub const Treap = @import("treap.zig").Treap;
```

## Signature

```zig
pub fn Treap(comptime Key: type, comptime compareFn: anytype) type
```

## Overview

`std.Treap` returns an intrusive randomized binary search tree type. Each inserted item is represented by a caller-owned `Node`; the treap stores pointers to those nodes and orders them by key.

The generated type stores:

- `root: ?*Node = null`
- `prng: Prng = .{}`

The internal PRNG is used only to assign node priorities for balancing.

## Generated Types

### `Node`

`Node` stores a key, random priority, parent pointer, and two child pointers. It provides:

- `next(node: *Node) ?*Node`
- `prev(node: *Node) ?*Node`

### `Entry`

`Entry` represents the lookup slot for a key. It is returned by `getEntryFor` or `getEntryForExisting` and is modified with:

```zig
pub fn set(self: *Entry, new_node: ?*Node) void
```

Passing a node inserts or replaces; passing `null` removes the existing node.

### `InorderIterator`

`InorderIterator.next` walks nodes in key order.

## Generated Functions

### `pub fn getMin(self: Self) ?*Node`

Returns the smallest node by key, or `null`.

### `pub fn getMax(self: Self) ?*Node`

Returns the largest node by key, or `null`.

### `pub fn getEntryFor(self: *Self, key: Key) Entry`

Looks up the entry slot for `key`. Use the returned entry to insert, replace, or remove a node.

### `pub fn getEntryForExisting(self: *Self, node: *Node) Entry`

Returns an entry for a node already inserted in the treap. Passing a node that is not inserted is undefined behavior.

### `pub fn inorderIterator(self: *Self) InorderIterator`

Returns an iterator starting at the minimum node.

## Example

```zig
const std = @import("std");

const Tree = std.Treap(u32, std.math.order);

var tree = Tree{};
var node: Tree.Node = undefined;

var entry = tree.getEntryFor(42);
entry.set(&node);

var it = tree.inorderIterator();
while (it.next()) |current| {
    _ = current.key;
}
```

## Notes

- The structure is intrusive: node storage belongs to the caller.
- Node keys are initialized by insertion.
- `getEntryForExisting` and node navigation assume the node is currently linked into the treap.
- Iteration order is ascending by key according to `compareFn`.

## See Also

- `std.math.order`
