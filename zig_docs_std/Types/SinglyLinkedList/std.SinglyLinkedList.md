# std.SinglyLinkedList

`std.SinglyLinkedList` imports the standard singly-linked intrusive list type.

## Source Declaration

```zig
pub const SinglyLinkedList = @import("SinglyLinkedList.zig");
```

## Overview

`std.SinglyLinkedList` stores a single pointer to the first node in a forward-only list.

The list is intrusive: `Node` contains only linkage fields. Store the node inside another payload type and recover the payload with `@fieldParentPtr`.

## Fields

- `first`: first node in the list, or null.

## Types

- `Node`: linkage node with a `next` pointer.

## Common Operations

- `prepend(new_node)`: insert at the beginning.
- `remove(node)`: remove a known node, asserting it is present.
- `popFirst()`: remove and return the first node.
- `len()`: count nodes in O(n).
- `Node.insertAfter(new_node)`: insert after a node.
- `Node.removeNext()`: remove the node after this node.
- `Node.findLast()`: find the final node in O(n).
- `Node.countChildren()`: count following nodes in O(n).
- `Node.reverse(indirect)`: reverse a list segment in place.

## Notes

- The list does not allocate.
- Arbitrary removal is O(n) because only forward links are stored.
- The caller owns node storage and payload lifetime.

## See Also

- `std.DoublyLinkedList`
