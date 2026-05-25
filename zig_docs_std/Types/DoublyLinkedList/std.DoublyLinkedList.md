# std.DoublyLinkedList

`std.DoublyLinkedList` imports the standard doubly-linked intrusive list type.

## Source Declaration

```zig
pub const DoublyLinkedList = @import("DoublyLinkedList.zig");
```

## Overview

`std.DoublyLinkedList` stores pointers to both the first and last node in a list. Each node stores pointers to the previous and next node, so traversal can move forward or backward.

The list is intrusive: `Node` contains only linkage fields. Store the node inside another payload type and recover the payload with `@fieldParentPtr`.

## Fields

- `first`: first node in the list, or null.
- `last`: last node in the list, or null.

## Types

- `Node`: linkage node with `prev` and `next` pointers.

## Common Operations

- `append(new_node)`: insert at the end.
- `prepend(new_node)`: insert at the beginning.
- `insertAfter(existing_node, new_node)`: insert after an existing node.
- `insertBefore(existing_node, new_node)`: insert before an existing node.
- `remove(node)`: remove a known node.
- `pop()`: remove and return the last node.
- `popFirst()`: remove and return the first node.
- `concatByMoving(list2)`: append another list and clear it.
- `len()`: count nodes in O(n).

## Notes

- Removing an arbitrary known node is O(1).
- The list does not allocate.
- The caller owns node storage and payload lifetime.

## See Also

- `std.SinglyLinkedList`
