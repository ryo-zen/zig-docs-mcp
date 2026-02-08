# std.crypto.auth

Message Authentication Code (MAC) functions. MACs verify both the integrity and authenticity of a message using a shared secret key. Unlike digital signatures, MACs are symmetric - both parties need the same key.

## Common Interface

All MAC types share a similar API:

```zig
// One-shot MAC computation
var mac: [Mac.mac_length]u8 = undefined;
Mac.create(&mac, data, &key);

// Incremental MAC computation
var ctx = Mac.init(&key);
ctx.update(chunk1);
ctx.update(chunk2);
ctx.final(&mac);
```

**Shared methods:**

| Method | Description |
|--------|-------------|
| `create` | `fn create(out: *[mac_length]u8, msg: []const u8, key: *const [key_length]u8) void` - One-shot MAC |
| `init` | `fn init(key: *const [key_length]u8) @This()` - Create incremental MAC context |
| `update` | `fn update(self: *@This(), data: []const u8) void` - Feed data incrementally |
| `final` | `fn final(self: *@This(), out: *[mac_length]u8) void` - Finalize and produce MAC |

**Shared constants:**

| Constant | Description |
|----------|-------------|
| `key_length` | Key size in bytes |
| `mac_length` | Output MAC size in bytes |

## Namespaces

### `hmac`

HMAC (Hash-based MAC) - The most widely used MAC construction. Built on top of any cryptographic hash function. Used in TLS, JWT, OAuth, and most authentication protocols.

| Type | Key | MAC | Based on |
|------|-----|-----|----------|
| `HmacSha256` | 32 B | 32 B | SHA-256 |
| `HmacSha512` | 64 B | 64 B | SHA-512 |

```zig
const HmacSha256 = std.crypto.auth.hmac.HmacSha256;

const key: [HmacSha256.key_length]u8 = ...; // Shared secret
const message = "Authenticate this data";

// Compute MAC
var mac: [HmacSha256.mac_length]u8 = undefined;
HmacSha256.create(&mac, message, &key);

// Verify MAC (use timing-safe comparison!)
const received_mac: [32]u8 = ...; // From the other party
const valid = std.crypto.timing_safe.eql([32]u8, mac, received_mac);
```

### `siphash`

SipHash - Fast, short-output MAC designed for hash table keying and short message authentication. Not suitable as a general-purpose MAC for large data.

| Type | Key | MAC | Notes |
|------|-----|-----|-------|
| `SipHash64(c_rounds, d_rounds)` | 16 B | 8 B | 64-bit output |
| `SipHash128(c_rounds, d_rounds)` | 16 B | 16 B | 128-bit output |

```zig
const SipHash128 = std.crypto.auth.siphash.SipHash128(2, 4);

var mac: [SipHash128.mac_length]u8 = undefined;
SipHash128.create(&mac, data, &key);
```

### `cmac`

CMAC (Cipher-based MAC) - MAC based on block ciphers (AES). Used in protocols that already depend on AES.

| Type | Key | MAC | Notes |
|------|-----|-----|-------|
| `AesCmac` | 16 B | 16 B | Based on AES-128 |

### `cbc_mac`

CBC-MAC - Raw CBC-based MAC. Generally prefer CMAC which fixes CBC-MAC's weaknesses with variable-length messages.

### `aegis`

AEGIS-based MAC - Uses the AEGIS AEAD construction as a MAC. Very fast with AES hardware support.

| Type | Key | MAC | Notes |
|------|-----|-----|-------|
| `Aegis128LMac` | 16 B | 16/32 B | Fastest with AES-NI |
| `Aegis256Mac` | 32 B | 16/32 B | 256-bit key |

## MAC Selection Guide

| Need | Recommendation |
|------|---------------|
| General purpose | **HmacSha256** (universal, well-understood) |
| Protocol interoperability | **HmacSha256** (TLS, JWT, OAuth) |
| Hash table keying | **SipHash** (fast, short output) |
| AES-based environment | **AesCmac** or **Aegis128LMac** |
| Maximum speed (AES-NI) | **Aegis128LMac** |

## MAC vs Signature vs Hash

| Primitive | Key needed | Provides | Use case |
|-----------|-----------|----------|----------|
| Hash | None | Integrity only | Checksums, content addressing |
| MAC | Shared secret | Integrity + authenticity | API tokens, session validation |
| Signature | Key pair | Integrity + authenticity + non-repudiation | Document signing, identity proof |

## See Also

- **std.crypto.hash** - Unkeyed hash functions
- **std.crypto.aead** - Combined encryption + authentication
- **std.crypto.sign** - Asymmetric signatures (non-repudiation)
- **std.crypto.timing_safe** - Constant-time MAC comparison
