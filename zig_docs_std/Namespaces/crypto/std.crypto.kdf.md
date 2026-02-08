# std.crypto.kdf

Key Derivation Functions (KDFs). Derive one or more cryptographically strong keys from input keying material. Used to turn shared secrets (from DH or KEM) into usable encryption keys, or to derive multiple purpose-specific keys from a single master key.

## Namespaces

### `hkdf`

HMAC-based Key Derivation Function (RFC 5869). The standard KDF for deriving keys from high-entropy input material (shared secrets, master keys). Two-phase design: extract then expand.

**Available variants:**

| Type | Based on | PRK size |
|------|----------|----------|
| `HkdfSha256` | HMAC-SHA-256 | 32 B |
| `HkdfSha512` | HMAC-SHA-512 | 64 B |

**Phase 1: Extract** - Concentrate entropy into a fixed-size pseudorandom key (PRK):

```zig
const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;

// Extract: salt + input keying material -> PRK
const prk = Hkdf.extract(salt, &input_key_material);
// prk is [32]u8 for HkdfSha256
```

**Phase 2: Expand** - Derive output keys from the PRK:

```zig
// Expand: PRK + context info -> derived key(s)
var derived_key: [32]u8 = undefined;
Hkdf.expand(&derived_key, prk, "context-string", .{});
```

**Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `extract` | `fn extract(salt: []const u8, ikm: []const u8) [prk_length]u8` | Extract PRK from input keying material |
| `expand` | `fn expand(out: []u8, prk: [prk_length]u8, info: []const u8, opts: anytype) void` | Expand PRK into derived key material |

## Common Patterns

### Deriving Multiple Keys from a Shared Secret

```zig
const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;

pub fn deriveSessionKeys(shared_secret: [32]u8) struct {
    client_write_key: [32]u8,
    server_write_key: [32]u8,
    client_write_iv: [12]u8,
    server_write_iv: [12]u8,
} {
    // Extract: concentrate entropy
    const prk = Hkdf.extract("my-protocol-v1", &shared_secret);

    // Expand: derive purpose-specific keys using different context strings
    var client_key: [32]u8 = undefined;
    var server_key: [32]u8 = undefined;
    var client_iv: [12]u8 = undefined;
    var server_iv: [12]u8 = undefined;

    Hkdf.expand(&client_key, prk, "client-write-key", .{});
    Hkdf.expand(&server_key, prk, "server-write-key", .{});
    Hkdf.expand(&client_iv, prk, "client-write-iv", .{});
    Hkdf.expand(&server_iv, prk, "server-write-iv", .{});

    return .{
        .client_write_key = client_key,
        .server_write_key = server_key,
        .client_write_iv = client_iv,
        .server_write_iv = server_iv,
    };
}
```

### Key Exchange + Key Derivation

```zig
const X25519 = std.crypto.dh.X25519;
const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

pub fn secureChannel(peer_pk: [32]u8, our_sk: [32]u8) ![32]u8 {
    // Key exchange
    const shared = try X25519.scalarmult(peer_pk, our_sk);

    // Derive encryption key (never use raw shared secret directly!)
    const prk = Hkdf.extract("", &shared);
    var enc_key: [32]u8 = undefined;
    Hkdf.expand(&enc_key, prk, "encryption", .{});

    return enc_key;
}
```

## HKDF vs Password Hashing

| Use case | Function | Why |
|----------|----------|-----|
| Shared secret -> key | **HKDF** | Input already has high entropy |
| Password -> key | **Argon2** (`std.crypto.pwhash`) | Needs slow, memory-hard function |
| Master key -> subkeys | **HKDF** | Deterministic key hierarchy |

HKDF is fast by design - it assumes high-entropy input. For passwords (low entropy), use `std.crypto.pwhash.argon2` instead.

## See Also

- **std.crypto.dh** - Key exchange (provides input keying material)
- **std.crypto.kem** - Post-quantum key encapsulation (provides shared secrets)
- **std.crypto.pwhash** - Password-based key derivation (for low-entropy input)
- **std.crypto.auth.hmac** - Underlying HMAC primitive used by HKDF
