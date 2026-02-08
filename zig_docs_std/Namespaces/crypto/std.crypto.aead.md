# std.crypto.aead

Authenticated Encryption with Associated Data (AEAD). Provides both confidentiality (encryption) and integrity/authenticity (authentication) in a single operation. Associated data is authenticated but not encrypted, useful for headers and metadata.

## Common Interface

All AEAD types share the same API:

```zig
// Encrypt plaintext, producing ciphertext + authentication tag
Aead.encrypt(ciphertext, &tag, plaintext, associated_data, nonce, key);

// Decrypt ciphertext, verifying the authentication tag
try Aead.decrypt(plaintext, ciphertext, tag, associated_data, nonce, key);
// Returns error.AuthenticationFailed if ciphertext or AD was tampered with
```

**Shared methods on all AEAD types:**

| Method | Description |
|--------|-------------|
| `encrypt` | `fn encrypt(c: []u8, tag: *[tag_length]u8, m: []const u8, ad: []const u8, nonce: [nonce_length]u8, key: [key_length]u8) void` |
| `decrypt` | `fn decrypt(m: []u8, c: []const u8, tag: [tag_length]u8, ad: []const u8, nonce: [nonce_length]u8, key: [key_length]u8) AuthenticationError!void` |

**Shared constants:**

| Constant | Description |
|----------|-------------|
| `key_length` | Key size in bytes |
| `nonce_length` | Nonce/IV size in bytes |
| `tag_length` | Authentication tag size in bytes |

## Namespaces

### `chacha_poly`

ChaCha20-Poly1305 - Modern, fast, patent-free AEAD. Recommended for most uses, especially on platforms without hardware AES.

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `ChaCha20Poly1305` | 32 B | 12 B | 16 B | RFC 8439, TLS 1.3 |
| `XChaCha20Poly1305` | 32 B | 24 B | 16 B | Extended nonce (safer for random nonces) |

```zig
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

const key: [32]u8 = ...; // Use std.crypto.random.bytes()
var nonce: [12]u8 = undefined;
std.crypto.random.bytes(&nonce);

// Encrypt
var ciphertext: [plaintext.len]u8 = undefined;
var tag: [16]u8 = undefined;
ChaCha20Poly1305.encrypt(&ciphertext, &tag, plaintext, "metadata", nonce, key);

// Decrypt (fails if tampered)
var decrypted: [ciphertext.len]u8 = undefined;
try ChaCha20Poly1305.decrypt(&decrypted, &ciphertext, tag, "metadata", nonce, key);
```

### `aes_gcm`

AES-GCM - Hardware-accelerated on CPUs with AES-NI. Preferred when hardware acceleration is available.

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `Aes128Gcm` | 16 B | 12 B | 16 B | 128-bit AES |
| `Aes256Gcm` | 32 B | 12 B | 16 B | 256-bit AES, higher security margin |

```zig
const Aes256Gcm = std.crypto.aead.aes_gcm.Aes256Gcm;

const key: [32]u8 = ...;
var nonce: [12]u8 = undefined;
std.crypto.random.bytes(&nonce);

var ciphertext: [plaintext.len]u8 = undefined;
var tag: [16]u8 = undefined;
Aes256Gcm.encrypt(&ciphertext, &tag, plaintext, "", nonce, key);
```

### `aegis`

AEGIS - State-of-the-art AEAD, extremely fast with AES hardware support. Newer standard (RFC 9312).

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `Aegis128L` | 16 B | 16 B | 16/32 B | Fastest, 128-bit security |
| `Aegis256` | 32 B | 32 B | 16/32 B | 256-bit security |
| `Aegis128X2` | 16 B | 16 B | 16/32 B | Parallelized variant |
| `Aegis128X4` | 16 B | 16 B | 16/32 B | Highly parallelized |
| `Aegis256X2` | 32 B | 32 B | 16/32 B | Parallelized 256-bit |
| `Aegis256X4` | 32 B | 32 B | 16/32 B | Highly parallelized 256-bit |

### `aes_ocb`

AES-OCB - Single-pass AEAD with excellent performance. Patent-free since 2021.

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `Aes128Ocb` | 16 B | 12 B | 16 B | 128-bit AES |
| `Aes256Ocb` | 32 B | 12 B | 16 B | 256-bit AES |

### `aes_siv`

AES-SIV - Nonce-misuse resistant. Safe even if nonces are accidentally reused (leaks only equality of plaintexts).

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `Aes128SivMac` | 32 B | variable | 16 B | Nonce-misuse resistant |
| `Aes256SivMac` | 64 B | variable | 16 B | Nonce-misuse resistant |

### `aes_gcm_siv`

AES-GCM-SIV - Nonce-misuse resistant variant of AES-GCM. Combines GCM performance with SIV safety.

### `aes_ccm`

AES-CCM - Combined counter mode with CBC-MAC. Used in Bluetooth, ZigBee, and IEEE 802.15.4.

### `ascon`

Ascon AEAD - Lightweight, designed for constrained environments. NIST Lightweight Cryptography standard.

### `isap`

ISAP - Side-channel resistant AEAD based on Ascon. Designed for leakage resilience.

### `salsa_poly`

Salsa20-Poly1305 - Predecessor to ChaCha20-Poly1305. Use ChaCha20-Poly1305 for new designs.

| Type | Key | Nonce | Tag | Notes |
|------|-----|-------|-----|-------|
| `XSalsa20Poly1305` | 32 B | 24 B | 16 B | Extended nonce variant |

## Scheme Selection Guide

| Need | Recommendation |
|------|---------------|
| General purpose | **ChaCha20Poly1305** (fast everywhere, no HW needed) |
| Hardware AES available | **Aegis128L** (fastest) or **Aes256Gcm** |
| Nonce reuse safety | **Aes128SivMac** or **AesGcmSiv** |
| Constrained / embedded | **Ascon** |
| Maximum throughput | **Aegis128X4** (with AES-NI) |
| TLS 1.3 compliance | **ChaCha20Poly1305** or **Aes256Gcm** |
| Legacy NaCl compatibility | **XSalsa20Poly1305** |

## Security Rules

- **Never reuse a nonce** with the same key (except with SIV modes)
- **Always check decryption errors** - `error.AuthenticationFailed` means data was tampered with
- **Use random nonces** via `std.crypto.random.bytes()` or a counter
- **XChaCha20Poly1305** has a 24-byte nonce - safer for random nonce generation (negligible collision probability)
- **Associated data** is authenticated but not encrypted - use it for message headers, version numbers, etc.

## See Also

- **std.crypto.stream** - Raw stream ciphers (no authentication - prefer AEAD)
- **std.crypto.auth** - Standalone MAC functions
- **std.crypto.nacl** - High-level NaCl Box/SecretBox API using AEAD internally
