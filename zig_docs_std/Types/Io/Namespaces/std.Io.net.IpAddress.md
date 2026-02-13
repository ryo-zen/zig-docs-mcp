# std.Io.net.IpAddress

📚 **[See Comprehensive Examples & Tests](../../Examples/test_ip_address_comprehensive.zig)**

Tagged union capable of holding either an IPv4 or IPv6 address.

## Quick Start

```zig
const std = @import("std");
const net = std.Io.net;

// Parse "Any" address (checks IPv4 then IPv6)
const addr = try net.IpAddress.parse("127.0.0.1", 8080);

// Switch on family
switch (addr) {
    .ip4 => |v4| std.debug.print("IPv4: {}\n", .{v4}),
    .ip6 => |v6| std.debug.print("IPv6: {}\n", .{v6}),
}

// Access port polymorphically
std.debug.print("Port: {}\n", .{addr.getPort()});
```

---

## Overview

`std.Io.net.IpAddress` is the primary type for representing network endpoints in Zig. It is a tagged union that wraps `Ip4Address` and `Ip6Address`, allowing functions to accept any valid IP address type.

**Key Characteristics:**
- **Polymorphic**: Used by `socket.bind`, `connect`, and `listen` to support dual-stack networking.
- **Convenience Methods**: Provides unified helpers like `getPort` and `setPort` that work on both variants.
- **Parsing Power**: Can parse literals with ports (e.g., `127.0.0.1:80`) via `parseLiteral`.

## Fields

`ip4: Ip4Address`
The IPv4 variant.

`ip6: Ip6Address`
The IPv6 variant.

## Core Functions

`pub fn parse(text: []const u8, port: u16) !IpAddress`

Parses a string into an address. Tries IPv4 first, then IPv6.
- **text**: The IP string (e.g., "1.2.3.4" or "::1").
- **port**: The port to assign.

------

`pub fn parseLiteral(text: []const u8) ParseLiteralError!IpAddress`

Parses a string that includes the port.
- **IPv4**: "1.2.3.4:80"
- **IPv6**: "[::1]:80" (Brackets required for IPv6)

------

`pub fn resolve(io: Io, text: []const u8, port: u16) !IpAddress`

Resolves an IP string that might include a scope ID (e.g., "fe80::1%eth0").
- **Requires `Io`**: Needed for interface name lookup.

------

`pub fn getPort(a: IpAddress) u16`

Returns the port number regardless of the active union tag.

------

`pub fn setPort(a: *IpAddress, port: u16) void`

Sets the port number for the active union tag.

## Network Operations

`pub fn bind(address: *const IpAddress, io: Io, options: BindOptions) BindError!Socket`

Creates a socket and binds it to this address. Used for receiving UDP or listening for TCP.

`pub fn connect(address: IpAddress, io: Io, options: ConnectOptions) ConnectError!Stream`

Initiates a TCP connection to this address.

`pub fn listen(address: IpAddress, io: Io, options: ListenOptions) ListenError!Server`

Binds and listens for incoming TCP connections. Returns a `Server`.

## Usage Patterns

### Generic Server Binding
Bind to any valid address string provided by configuration.

```zig
const addr = try net.IpAddress.parseLiteral(config.listen_address); // e.g. "0.0.0.0:80"
const server = try addr.listen(io, .{});
```

### Handling Client Connections
When accepting connections, store the remote address as `IpAddress` to handle both IPv4 and IPv6 clients uniformly.

```zig
var client_addr: net.IpAddress = undefined;
// ... accept connection ...
std.debug.print("Client connected from: {}\n", .{client_addr});
```

## Error Sets

- `ParseLiteralError`: Invalid format or missing port.
- `BindError`: Address in use, permission denied, etc.
- `ConnectError`: Connection refused, network unreachable, etc.
