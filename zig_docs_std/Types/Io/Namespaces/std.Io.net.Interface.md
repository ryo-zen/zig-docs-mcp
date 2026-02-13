# std.Io.net.Interface

Identification of a network interface (e.g., "eth0", "wlan0", "lo").

## Quick Start

```zig
const net = std.Io.net;

// Check for "none" interface
const iface = net.Interface{ .index = 0 };
if (iface.isNone()) {
    std.debug.print("No interface specified\n", .{});
}

// Get interface name (Platform dependent availability)
// const name = try iface.name(io);
```

---

## Overview

`std.Io.net.Interface` is a lightweight struct wrapping a network interface index. It is used to identify specific network interfaces for operations like multicasting or scoping IPv6 addresses.

**Key Characteristics:**
- **Index-based**: Wraps a `u32` index utilized by the operating system.
- **Platform interoperable**: Can be converted to/from system interface indices.
- **Zero-cost**: Same memory layout as a `u32`.

## Fields

`index: u32`

The system-specific index of the interface.
- `0` is reserved for "none" or "any" depending on context.
- Positive values correspond to specific interfaces.

## Values

`pub const none = Interface{ .index = 0 };`

Represents no specific interface. Used as a default value.

## Functions

`pub fn isNone(i: Interface) bool`

Returns `true` if the interface index is 0 (none).

------

`pub fn name(i: Interface, io: Io) NameError!Name`

Retrieves the name of the interface (e.g., "eth0").
- **io**: The I/O interface context.
- **Returns**: A `Name` struct containing the interface name.
- **Note**: Implementation availability varies by platform and backend.

## Types

`pub const Name = struct { ... }`

Represents a network interface name.
- Used as the return value of `name()`.
- Likely contains an internal buffer or slice.

## Error Sets

**NameError**
Errors that can occur when resolving an interface index to a name.
- `InterfaceNotFound`: The index does not correspond to a valid interface.
- `SystemResources`: Insufficient resources to perform the query.

**ResolveError**
Errors that can occur when resolving an interface name to an index.
- `InterfaceNotFound`: The name does not exist.

## See Also

- [std.Io.net.Ip6Address](std.Io.net.Ip6Address.md) - Uses `Interface` for scope ID.
- [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - General IP address handling.
