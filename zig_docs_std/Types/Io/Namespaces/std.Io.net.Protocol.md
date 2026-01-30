# std.Io.net.Protocol

📚 **[See Comprehensive Examples & Tests](../../Examples/test_protocol_comprehensive.zig)**

Enumeration of IP protocol numbers (IANA Assigned).

## Quick Start

```zig
const std = @import("std");
const Protocol = std.Io.net.Protocol;

pub fn identify(p: Protocol) []const u8 {
    return switch (p) {
        .tcp => "TCP (Reliable Stream)",
        .udp => "UDP (Datagram)",
        .icmp => "ICMP (Diagnostics)",
        else => "Other",
    };
}
```

---

## Overview

`std.Io.net.Protocol` is a `u32` backed enum representing standard Internet Protocol numbers as defined by IANA. These values are typically found in the "Protocol" field of an IPv4 header or the "Next Header" field of an IPv6 header.

**Key Characteristics:**
- **Standard Values**: Matches standard IANA assignments (TCP=6, UDP=17).
- **Extensive**: Covers common protocols (ICMP, IGMP, TCP, UDP) and IPv6 extensions.
- **Type Safety**: Enforces valid protocol usage in APIs that consume it.

## Common Protocols

`tcp = 6`
Transmission Control Protocol. Connection-oriented, reliable stream service.

`udp = 17`
User Datagram Protocol. Connectionless, unreliable datagram service.

`icmp = 1`
Internet Control Message Protocol. Used for ping (echo) and error reporting.

`icmpv6 = 58`
ICMP for IPv6.

`ipv6 = 41`
IPv6 encapsulation.

`raw = 255`
Reserved for Raw IP packets.

## All Values

| Value | Name | Description |
|-------|------|-------------|
| 0 | `hopopts` | IPv6 Hop-by-Hop Option |
| 1 | `icmp` | Internet Control Message |
| 2 | `igmp` | Internet Group Management |
| 4 | `ipip` | IPIP Encapsulation |
| 6 | `tcp` | Transmission Control |
| 8 | `egp` | Exterior Gateway Protocol |
| 12 | `pup` | PUP Protocol |
| 17 | `udp` | User Datagram |
| 22 | `idp` | XNS IDP |
| 29 | `tp` | SO Transport Protocol Class 4 |
| 33 | `dccp` | Datagram Congestion Control |
| 41 | `ipv6` | IPv6 Encapsulation |
| 43 | `routing` | IPv6 Routing Header |
| 44 | `fragment` | IPv6 Fragment Header |
| 46 | `rsvp` | Resource Reservation |
| 47 | `gre` | Generic Routing Encapsulation |
| 50 | `esp` | Encap Security Payload |
| 51 | `ah` | Authentication Header |
| 58 | `icmpv6` | ICMP for IPv6 |
| 59 | `none` | No Next Header (IPv6) |
| 60 | `dstopts` | IPv6 Destination Options |
| 92 | `mtp` | Multicast Transport |
| 94 | `beetph` | BEET Esp Header |
| 98 | `encap` | Encapsulation Header |
| 103 | `pim` | Protocol Independent Multicast |
| 108 | `comp` | Compression Header |
| 132 | `sctp` | Stream Control Transmission |
| 135 | `mh` | Mobility Header |
| 136 | `udplite` | UDP-Lite |
| 137 | `mpls` | MPLS-in-IP |
| 143 | `ethernet` | Ethernet-within-IPv6 |
| 255 | `raw` | Raw IP Packet |
| 262 | `mptcp` | Multipath TCP |

## Usage Patterns

### Packet Inspection
When parsing raw network packets (e.g., from a raw socket or pcap file), map the header byte to this enum to dispatch handlers.

```zig
const next_header: u8 = packet[9]; // IPv4 Protocol field
const protocol: std.Io.net.Protocol = @enumFromInt(next_header);

switch (protocol) {
    .tcp => processTcp(payload),
    .udp => processUdp(payload),
    else => std.debug.print("Unknown protocol: {}\n", .{{protocol}}),
}
```

### Raw Sockets
(Future/Advanced) Used when creating sockets that bypass the transport layer.

```zig
// Hypothetical raw socket creation
// const s = try socket(domain, .raw, .icmp);
```

## Source
Values are derived from the [IANA Protocol Numbers Registry](https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml).

```
