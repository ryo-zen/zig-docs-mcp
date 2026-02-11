# std.process.ProtectMemoryOptions

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.ProtectMemoryOptions` is a packed structure used by `std.process.protectMemory()` to set the access permissions for a specific region of memory. It allows fine-grained control over whether a memory block can be read from, written to, or executed.

---

## Fields

`read: bool = false`
------
If true, the memory region is made readable.

`write: bool = false`
------
If true, the memory region is made writable. **Note:** Most operating systems do not allow memory to be writable without also being readable.

`execute: bool = false`
------
If true, the memory region is made executable (allowing code stored in that memory to be run).

---

## Usage Example

```zig
const options = std.process.ProtectMemoryOptions{
    .read = true,
    .write = false,
    .execute = false,
};

// Make a page of memory read-only
try std.process.protectMemory(page_slice, options);
```

---

## See Also

- **std.process.protectMemory** - The function that consumes this struct.
- **std.process.lockMemory** - For preventing memory from being swapped to disk.
