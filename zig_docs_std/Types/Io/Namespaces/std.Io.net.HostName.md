# std.Io.net.HostName

📚 **[See Comprehensive Examples & Tests](../../Examples/test_hostname_comprehensive.zig)**

A validated, immutable domain name or host string.

## Quick Start

### Most Common Patterns

**Validate and Initialize**
```zig
const HostName = std.Io.net.HostName;

// Validation (RFC 1123)
try HostName.validate("google.com");

// Initialization (wraps a string slice)
const hn = try HostName.init("localhost");
std.debug.print("Host: {s}\n", .{hn.bytes});
```

**DNS Lookup (Asynchronous)**
```zig
var buffer: [16]std.Io.net.HostName.LookupResult = undefined;
var queue = std.Io.Queue(std.Io.net.HostName.LookupResult).init(&buffer);

var canon_buf: [HostName.max_len]u8 = undefined;
try hn.lookup(io, &queue, .{
    .port = 443,
    .canonical_name_buffer = &canon_buf,
});

while (true) {
    const result = queue.getOneUncancelable(io) catch |err| {
  if (err == error.Closed) break;
  return err;
    };
    switch (result) {
  .address => |addr| std.debug.print("Address: {}\n", .{addr}),
  .canonical_name => |canon| std.debug.print("CNAME: {s}\n", .{canon.bytes}),
    }
}
```

**Connect by HostName**
```zig
const stream = try hn.connect(io, 443, .{});
defere stream.close(io);
```

### Key Operations
- `HostName.init` - Validates and creates a HostName from a string
- `.lookup` - Performs DNS resolution and populates a result queue
- `.connect` - Resolves and connects to the first available address
- `.eql` - Case-insensitive comparison of domain names

### ⚠️ Critical: Memory Management
`HostName` does **not** copy the input string. The `bytes` field points to the original memory provided to `init`. You must ensure the source string remains valid while the `HostName` is in use.

---

## Overview

`std.Io.net.HostName` represents a valid network host name. It ensures that names adhere to strict networking standards (RFC 1123) before allowing them to be used in lookup or connection operations.

**Key Characteristics:**
- **Immutable**: Once initialized, the underlying string is treated as a validated host name.
- **Standards Compliant**: Validates against RFC 1123 (alphanumeric, hyphens, dots, length limits).
- **Case-Insensitive**: Implements `eql` according to DNS standards (Google.com == google.com).
- **Subdomain Aware**: Provides `sameParentDomain` for checking organizational relationships.

**When to use HostName:**
- Resolving domain names to IP addresses.
- Connecting to services where only the domain name is known.
- Validating user input for hostnames or domain fields.
- Comparing domain names in a standard-compliant way.

## Fields

`bytes: []const u8`

The raw string slice of the host name. This memory is externally managed and must remain valid for the lifetime of the `HostName` object.

## Constants

`max_len: usize = 255`

The maximum length allowed for a host name according to standard DNS limits.

## Functions

### `pub fn init(bytes: []const u8) ValidateError!HostName`
Validates the input string and returns a `HostName` wrapper. Does not copy the input memory.

------

### `pub fn validate(bytes: []const u8) ValidateError!void`
Checks if a string is a valid host name according to RFC 1123.
- Length must be `<= max_len`.
- Must be valid UTF-8.
- Characters must be alphanumeric, `.`, or `-`.

------

### `pub fn lookup(host_name: HostName, io: Io, resolved: *Io.Queue(LookupResult), options: LookupOptions) LookupError!void`
Performs asynchronous DNS resolution.
- Results (addresses and exactly one canonical name) are added to the `resolved` queue.
- The queue is closed automatically when resolution completes or fails.
- **Options**: Requires a `port` and a `canonical_name_buffer` (must be `max_len` bytes).

------

### `pub fn connect(host_name: HostName, io: Io, port: u16, options: IpAddress.ConnectOptions) ConnectError!Stream`
Resolves the host name and attempts to connect to the resolved addresses in order. Returns the first successful connection.

------

### `pub fn eql(a: HostName, b: HostName) bool`
Compares two host names for equality. The comparison is **case-insensitive**, following DNS standards.

------

### `pub fn sameParentDomain(parent_host: HostName, child_host: HostName) bool`
Returns `true` if `child_host` is a subdomain of `parent_host` (e.g., `docs.ziglang.org` is a subdomain of `ziglang.org`).

## Types

### `LookupResult` (Union)
The result of a DNS lookup operation.
- `.address: IpAddress` - A resolved IP address.
- `.canonical_name: HostName` - The canonical name (CNAME) of the host.

### `LookupOptions` (Struct)
- `.port: u16` - Port to use for resolved addresses.
- `.canonical_name_buffer: *[max_len]u8` - Buffer to store the canonical name.

## Usage Patterns

### Pattern 1: Multi-Protocol DNS Client

```zig
const hn = try HostName.init("example.com");
var buffer: [16]HostName.LookupResult = undefined;
var queue = std.Io.Queue(HostName.LookupResult).init(&buffer);
var canon_buf: [HostName.max_len]u8 = undefined;

try hn.lookup(io, &queue, .{
    .port = 80,
    .canonical_name_buffer = &canon_buf,
});

while (true) {
    const result = queue.getOneUncancelable(io) catch |err| {
  if (err == error.Closed) break;
  return err;
    };
    // Process addresses...
}
```

### Pattern 2: Domain Validation Utility

```zig
fn isSafeDomain(input: []const u8) bool {
    const hn = HostName.init(input) catch return false;
    const trusted = HostName.init("internal.corp") catch return false;

    return trusted.sameParentDomain(hn);
}
```

## Debug Checklist

1. ✅ **Memory Lifetime**: Does the string passed to `init` outlive the `HostName` object?
2. ✅ **Brackets in IPv6**: HostName is for domain names. For IP literals, use `IpAddress.parseLiteral` (which handles brackets like `[::1]`).
3. ✅ **Queue Capacity**: `lookup` is guaranteed not to block if the provided queue has a capacity of at least 16.
4. ✅ **Canonical Name Buffer**: Ensure the buffer provided to `LookupOptions` is exactly `HostName.max_len` bytes.

## Performance Tips

1. **Avoid repetitive validation**: Once you have a `HostName` object, you know the content is valid. Pass the `HostName` object instead of the raw string.
2. **Reuse lookup queues**: While `lookup` closes the queue, you can re-initialize it with the same buffer for subsequent lookups.
3. **Connect directly**: Use `hn.connect()` instead of manually resolving then connecting if you only need the first successful connection.

## See Also

- [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - IP address management
- [std.Io.Queue](../Types/std.Io.Queue.md) - For processing lookup results
- [std.Io.net.Stream](std.Io.net.Stream.md) - Network streams returned by `connect`
