# std.Io.net.Ip4Address

📚 **[See Comprehensive Examples & Tests](../../../../Examples/test_socket_basic.zig)**

## Quick Start

**Parsing and Formatting**
```zig
const std = @import("std");
const net = std.Io.net;

pub fn main() !void {
    // Parse from string
    const addr = try net.IpAddress.parse("192.168.1.1", 8080);
    
    // Check properties
    std.debug.print("Port: {}\n", .{@intCast(addr.port)});
    
    // Format back to string
    var buf: [64]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    try addr.format(fbs.writer());
    
    std.debug.print("Formatted: {s}\n", .{fbs.getWritten()});
}
```

---

## Overview

`std.Io.net.Ip4Address` represents an IPv4 address and port combination (e.g., `127.0.0.1:80`). It is a fundamental type for network operations, used for binding servers and connecting clients.

- **Memory Layout:** Contains a 4-byte address array and a 16-bit port.
- **Protocol Agnostic:** Used by both TCP (Stream) and UDP (Socket) operations.
- **Convenience:** Provides helpers for common addresses like loopback and unspecified (0.0.0.0).

## Fields

`bytes: [4]u8`
The raw IPv4 address bytes in network byte order (Big Endian).
Example: `127.0.0.1` -> `.{ 127, 0, 0, 1 }`

`port: u16`
The port number.
Example: `80`

## Functions

### `pub fn parse(buffer: []const u8, port: u16) ParseError!Ip4Address`
Parses a dot-decimal IPv4 string (e.g., "192.168.0.1") and combines it with a port number.

- **Parameters:**
  - `buffer`: The string slice containing the IP address.
  - `port`: The port number to assign.
- **Returns:** An `Ip4Address` struct.

**Example:**
```zig
const addr = try net.IpAddress.parse("10.0.0.5", 443);
```

------

### `pub fn format(a: Ip4Address, w: *Io.Writer) Io.Writer.Error!void`
Writes the string representation of the address (e.g., "127.0.0.1:8080") to the provided writer.

- **Note:** This enables the use of `{}` format specifier in `std.debug.print`.

------

### `pub fn loopback(port: u16) Ip4Address`
Returns the loopback address (`127.0.0.1`) with the specified port.

**Example:**
```zig
const local = net.Ip4Address.loopback(8080);
```

------

### `pub fn unspecified(port: u16) Ip4Address`
Returns the unspecified address (`0.0.0.0`) with the specified port.
Used when binding a server to listen on all available network interfaces.

**Example:**
```zig
const any = net.Ip4Address.unspecified(80);
```

------

### `pub fn eql(a: Ip4Address, b: Ip4Address) bool`
Compares two addresses for equality (matching both IP and port).

## Error Sets

### ParseError
- `InvalidCharacter`: String contains non-digit characters where digits were expected.
- `Overflow`: A segment of the IP address exceeds 255.
- `InvalidFormat`: The string is not in valid dot-decimal notation.

## See Also

- [std.Io.net.Ip6Address](std.Io.net.Ip6Address.md) - IPv6 equivalent.
- [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - Tagged union capable of holding either IPv4 or IPv6.