# std.crypto.hash

Cryptographic hash functions for data integrity, content addressing, and fingerprinting. All hash types implement a common interface allowing algorithm-agnostic code via comptime polymorphism.

## Common Interface

All hash types share the same API:

```zig
// One-shot hashing (most common)
var digest: [Hash.digest_length]u8 = undefined;
Hash.hash(data, &digest, .{});

// Incremental hashing (for streaming/large data)
var h = Hash.init(.{});
h.update(chunk1);
h.update(chunk2);
h.final(&digest);
```

**Shared methods on all hash types:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `hash` | `fn hash(data: []const u8, out: *[digest_length]u8, options: Options) void` | One-shot hash of complete data |
| `init` | `fn init(options: Options) @This()` | Create incremental hasher |
| `update` | `fn update(self: *@This(), data: []const u8) void` | Feed data incrementally |
| `final` | `fn final(self: *@This(), out: *[digest_length]u8) void` | Finalize and produce digest |

**Shared constants:**

| Constant | Type | Description |
|----------|------|-------------|
| `digest_length` | `comptime_int` | Output hash size in bytes |
| `block_length` | `comptime_int` | Internal block size in bytes |

## Types

### `Blake3`

Extremely fast, parallelizable, modern hash function. Recommended for most non-legacy use cases.

- **Digest size:** 32 bytes (256 bits), extensible to arbitrary length
- **Block size:** 64 bytes
- **Features:** Keyed hashing, key derivation, extensible output

```zig
const Blake3 = std.crypto.hash.Blake3;

// Simple hash
var digest: [32]u8 = undefined;
Blake3.hash("hello world", &digest, .{});

// Incremental (streaming large file)
var hasher = Blake3.init(.{});
while (true) {
    const n = try file.read(&buffer);
    if (n == 0) break;
    hasher.update(buffer[0..n]);
}
hasher.final(&digest);
```

### `Md5`

MD5 (128-bit). **Cryptographically broken** - only use for legacy compatibility (checksums, non-security fingerprinting).

- **Digest size:** 16 bytes (128 bits)
- **Block size:** 64 bytes

### `Sha1`

SHA-1 (160-bit). **Cryptographically broken** - only use for legacy compatibility (Git object hashes, older protocols).

- **Digest size:** 20 bytes (160 bits)
- **Block size:** 64 bytes

## Namespaces

### `sha2`

NIST-standardized SHA-2 family. Widely deployed, battle-tested, the default choice for interoperability.

| Type | Digest | Block | Use case |
|------|--------|-------|----------|
| `Sha224` | 28 B | 64 B | Truncated SHA-256 |
| `Sha256` | 32 B | 64 B | General purpose, TLS, Bitcoin |
| `Sha384` | 48 B | 128 B | Truncated SHA-512 |
| `Sha512` | 64 B | 128 B | Maximum security, large data |
| `Sha512256` | 32 B | 128 B | SHA-512 truncated to 256 bits |

```zig
const Sha256 = std.crypto.hash.sha2.Sha256;

var digest: [Sha256.digest_length]u8 = undefined;
Sha256.hash("The quick brown fox", &digest, .{});
```

### `sha3`

NIST-standardized SHA-3 family (Keccak-based). Independent design from SHA-2, good for defense-in-depth.

| Type | Digest | Block | Notes |
|------|--------|-------|-------|
| `Sha3_224` | 28 B | 144 B | SHA-3 variant |
| `Sha3_256` | 32 B | 136 B | SHA-3 variant |
| `Sha3_384` | 48 B | 104 B | SHA-3 variant |
| `Sha3_512` | 64 B | 72 B | SHA-3 variant |
| `Keccak256` | 32 B | 136 B | Pre-standardization Keccak (Ethereum) |
| `Keccak512` | 64 B | 72 B | Pre-standardization Keccak |
| `Shake128` | variable | 168 B | Extendable output (XOF) |
| `Shake256` | variable | 136 B | Extendable output (XOF) |
| `TurboShake128` | variable | 168 B | Faster XOF variant |
| `TurboShake256` | variable | 136 B | Faster XOF variant |

```zig
const Sha3_256 = std.crypto.hash.sha3.Sha3_256;

var digest: [Sha3_256.digest_length]u8 = undefined;
Sha3_256.hash("data", &digest, .{});
```

### `blake2`

Fast, secure alternative to SHA-2. Used in Argon2, WireGuard, and many modern protocols.

| Type | Digest | Block | Optimized for |
|------|--------|-------|---------------|
| `Blake2b256` | 32 B | 128 B | 64-bit platforms |
| `Blake2b512` | 64 B | 128 B | 64-bit platforms |
| `Blake2s128` | 16 B | 64 B | 32-bit platforms |
| `Blake2s256` | 32 B | 64 B | 32-bit platforms |

```zig
const Blake2b256 = std.crypto.hash.blake2.Blake2b256;

var digest: [Blake2b256.digest_length]u8 = undefined;
Blake2b256.hash("data", &digest, .{});
```

### `ascon`

Lightweight authenticated hash, designed for constrained environments (IoT, embedded).

| Type | Notes |
|------|-------|
| `AsconHash` | 256-bit hash |
| `AsconXof` | Extendable output |

### `composition`

Utilities for composing hash functions (e.g., running two hashes in parallel).

## Algorithm Selection Guide

| Need | Recommendation |
|------|---------------|
| General purpose, modern | **BLAKE3** (fastest, secure) |
| Interoperability / standards | **SHA-256** (NIST, TLS, most protocols) |
| Maximum digest size | **SHA-512** or **BLAKE2b-512** |
| Different design from SHA-2 | **SHA-3-256** (independent construction) |
| Constrained / embedded | **Ascon** |
| Legacy compatibility only | Md5, Sha1 (not for security) |

## Generic Hash Function Pattern

```zig
/// Hash data with any algorithm at comptime
fn computeHash(comptime Hash: type, data: []const u8) [Hash.digest_length]u8 {
    var digest: [Hash.digest_length]u8 = undefined;
    Hash.hash(data, &digest, .{});
    return digest;
}

// Usage:
const sha256_hash = computeHash(std.crypto.hash.sha2.Sha256, "data");
const blake3_hash = computeHash(std.crypto.hash.Blake3, "data");
```

## See Also

- **std.crypto.auth** - Keyed hash functions (HMAC, SipHash) for authentication
- **std.hash** - Non-cryptographic hashes (CRC32, Wyhash) for hash maps
- **std.crypto.kdf** - Key derivation using hash functions
