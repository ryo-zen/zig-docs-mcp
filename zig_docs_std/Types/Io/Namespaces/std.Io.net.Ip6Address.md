# std.Io.net.Ip6Address

📚 **[See Comprehensive Examples & Tests](../../Examples/test_ip6_address_comprehensive.zig)**

An IPv6 address in binary memory layout (16 bytes).

## Quick Start

```zig
const std = @import("std");
const Ip6Address = std.Io.net.Ip6Address;

// Parse string (no scope/interface)
const addr = try Ip6Address.parse("2001:db8::1", 8080);

// Resolve string (with scope/interface)
// Requires an Io context to look up interface indices
const scoped = try Ip6Address.resolve(io, "fe80::1%eth0", 22);

// Check properties
if (addr.isLoopBack()) {
    std.debug.print("Listening on localhost IPv6\n", .{});
}
```

---

## Overview

`std.Io.net.Ip6Address` represents an IPv6 socket address, containing the 128-bit address, port number, flow label, and scope ID (interface index). It is the IPv6 counterpart to `Ip4Address`.

**Key Characteristics:**
- **Standard Layout**: Matches `struct sockaddr_in6` layout on most platforms.
- **Scope Aware**: Includes an `Interface` field for scoped addresses (e.g., link-local addresses).
- **Flow Label**: Supports IPv6 flow labeling for QoS.

**When to use:**
- Networking with IPv6.
- Handling dual-stack applications (using IPv4-mapped IPv6 addresses).
- Working with link-local addresses that require a scope ID.

## Fields

`port: u16`

Port number (native endian).

------

`bytes: [16]u8`

The 128-bit IPv6 address in network byte order (Big Endian).

------

`flow: u32 = 0`

IPv6 Flow Information. Used for QoS handling by routers.

------

`interface: Interface = .none`

Scope ID / Interface Index. Crucial for link-local addresses (starts with `fe80::`) to identify which network interface to use.

## Core Functions

`pub fn parse(buffer: []const u8, port: u16) ParseError!Ip6Address`

Parses a standard IPv6 string literal (e.g., "2001:db8::1").
- **Does NOT** handle scope IDs (e.g., "%eth0"). Use `resolve` for those.
- Pure function, no I/O required.

------

`pub fn resolve(io: Io, buffer: []const u8, port: u16) ResolveError!Ip6Address`

Parses an IPv6 string that may contain a scope ID (e.g., "fe80::1%eth0").
- **Requires `Io`**: Needs to query the OS to convert interface names ("eth0") to indices.

------

`pub fn fromIp4(ip4: Ip4Address) Ip6Address`

Converts an IPv4 address into an IPv4-mapped IPv6 address (e.g., `::ffff:192.168.1.1`).
- Useful for dual-stack sockets that handle both protocols.

------

`pub fn loopback(port: u16) Ip6Address`

Returns the IPv6 loopback address (`::1`).

------

`pub fn unspecified(port: u16) Ip6Address`

Returns the "any" address (`::`), equivalent to `INADDR_ANY` in IPv4. Used when binding a server to all interfaces.

## Predicates

- `pub fn isLoopBack(a: Ip6Address) bool` - Checks for `::1`.
- `pub fn isMultiCast(a: Ip6Address) bool` - Checks for `ff00::/8`.
- `pub fn isLinkLocal(a: Ip6Address) bool` - Checks for `fe80::/10`.
- `pub fn isSiteLocal(a: Ip6Address) bool` - Checks for `fec0::/10` (Deprecated but still present).

## Usage Patterns

### Dual-Stack Server (IPv6 + IPv4)

To listen on both IPv4 and IPv6 using a single socket, bind to the IPv6 "unspecified" address (`::`). Note that `ipv6only` socket option usually needs to be disabled (default on some OSes, but explicit on others).

```zig
const addr = std.Io.net.Ip6Address.unspecified(8080);
// Bind...
```

### Link-Local Addressing

Link-local addresses are unique only within a specific network segment, so they require an interface scope.

```zig
// Parsing "fe80::1%wlan0"
const addr = try std.Io.net.Ip6Address.resolve(io, "fe80::1%wlan0", 1234);

// The .interface field is now populated with wlan0's index
std.debug.print("Scope ID: {}\n", .{addr.interface.index});
```

## Types

- `Policy` - Address selection policy (RFC 6724).
- `Unresolved` - Intermediate type for addresses with unresolved scope names.

## Error Sets

- `FormatError` - formatting failure.
- `ParseError` - invalid string format.
- `ResolveError` - interface name not found or system error.