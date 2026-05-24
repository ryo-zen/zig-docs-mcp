# std.crypto

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all crypto features

## Quick Start

### Most Common Patterns

**Hashing Data (SHA-256)**
```zig
const std = @import("std");
const sha256 = std.crypto.hash.sha2.Sha256;

pub fn hashData(data: []const u8) [32]u8 {
    var hash: [32]u8 = undefined;
    sha256.hash(data, &hash, .{});
    return hash;
}
```

**Password Hashing (Argon2)**
```zig
const std = @import("std");
const argon2 = std.crypto.pwhash.argon2;

pub fn hashPassword(password: []const u8, buf: []u8) !void {
    const salt = "random16bytesalt";  // Use crypto.random in production!
    try argon2.strHash(password, .{
  .allocator = std.heap.page_allocator,
  .params = argon2.Params.interactive,
  .encoding = .phc,
    }, buf);
}
```

**Authenticated Encryption (ChaCha20-Poly1305)**
```zig
const std = @import("std");
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

pub fn encryptMessage(plaintext: []const u8, ciphertext: []u8, tag: *[16]u8) !void {
    const key: [32]u8 = [_]u8{0} ** 32;  // Use a real key in production!
    const nonce: [12]u8 = [_]u8{0} ** 12;  // Use a unique nonce per message!
    ChaCha20Poly1305.encrypt(ciphertext, tag, plaintext, "", nonce, key);
}
```

**Constant-Time Comparison**
```zig
const std = @import("std");

pub fn verifyMAC(received: []const u8, expected: []const u8) bool {
    if (received.len != expected.len) return false;
    return std.crypto.timing_safe.eql([received.len]u8, received[0..received.len].*, expected[0..expected.len].*);
}
```

**Secure Memory Zeroing**
```zig
const std = @import("std");

pub fn clearSensitiveData(data: []u8) void {
    std.crypto.secureZero(u8, data);  // Cannot be optimized out by compiler
}
```

**Post-Quantum Signatures (ML-DSA/Dilithium)**
```zig
const std = @import("std");
const mldsa = std.crypto.sign.mldsa;

pub fn postQuantumSign(message: []const u8) ![2420]u8 {
    const seed: [32]u8 = [_]u8{0x42} ** 32;
    const key_pair = try mldsa.MLDSA44.KeyPair.generateDeterministic(seed);
    const signature = try key_pair.sign(message, null);
    return signature.toBytes();
}
```

**Post-Quantum Key Exchange (ML-KEM/Kyber)**
```zig
const std = @import("std");
const MLKem512 = std.crypto.kem.ml_kem.MLKem512;

pub fn postQuantumKeyExchange(io: std.Io) ![32]u8 {
    // Generate key pair (800 byte public key - much smaller than ML-DSA!)
    const seed: [MLKem512.seed_length]u8 = [_]u8{0x42} ** MLKem512.seed_length;
    const key_pair = try MLKem512.KeyPair.generateDeterministic(seed);

    // Encapsulate to create shared secret
    const encaps_result = key_pair.public_key.encaps(io);
    return encaps_result.shared_secret;
}
```

### Common Operations Quick Reference

| Operation | Namespace/Function | Example |
|-----------|-------------------|---------|
| Hash data | `std.crypto.hash.sha2.Sha256` | `Sha256.hash(data, &out, .{})` |
| Password hash | `std.crypto.pwhash.argon2` | `argon2.strHash(password, opts, buf, io)` |
| Encrypt/authenticate | `std.crypto.aead.chacha_poly` | `ChaCha20Poly1305.encrypt(ct, tag, pt, ad, nonce, key)` |
| Compare secrets | `std.crypto.timing_safe.eql` | `timing_safe.eql(T, a, b)` |
| Secure zero | `std.crypto.secureZero` | `secureZero(u8, slice)` |
| Random bytes | `io.randomSecure()` | `try io.randomSecure(&buffer)` |
| Classical signatures | `std.crypto.sign.Ed25519` | `key_pair.sign(message, null)` |
| Post-quantum signatures | `std.crypto.sign.mldsa.MLDSA44` | `key_pair.sign(message, null)` |
| Post-quantum key exchange | `std.crypto.kem.ml_kem.MLKem512` | `public_key.encaps(io)` |

### ⚠️ Critical: Security Best Practices

```zig
// ❌ WRONG - Never reuse nonces with same key
const nonce = [_]u8{0} ** 12;  // Static nonce
ChaCha20Poly1305.encrypt(ct1, tag1, pt1, "", nonce, key);
ChaCha20Poly1305.encrypt(ct2, tag2, pt2, "", nonce, key);  // INSECURE!

// ✅ CORRECT - Generate unique nonce for each encryption
var nonce: [12]u8 = undefined;
try io.randomSecure(&nonce);  // Random nonce
ChaCha20Poly1305.encrypt(ct, tag, pt, "", nonce, key);

// ❌ WRONG - Using weak password hashing
const hash = std.crypto.hash.sha2.Sha256.hash(password);  // Too fast!

// ✅ CORRECT - Use dedicated password hashing function
try std.crypto.pwhash.argon2.strHash(password, .{
    .allocator = allocator,
    .params = argon2.Params.interactive,
}, buf);

// ❌ WRONG - Non-constant-time MAC comparison
if (std.mem.eql(u8, received_mac, computed_mac)) { ... }  // Timing leak!

// ✅ CORRECT - Constant-time comparison
if (std.crypto.timing_safe.eql([32]u8, received_mac.*, computed_mac.*)) { ... }
```

---

## Overview

`std.crypto` is Zig's comprehensive cryptography namespace providing secure, audited implementations of modern cryptographic primitives including hashing, authenticated encryption, key derivation, and digital signatures.

**Key Characteristics:**
- **Modern algorithms** - Focuses on secure, contemporary cryptography (ChaCha20, Argon2, SHA-3, Ed25519)
- **Side-channel resistant** - Constant-time operations where timing attacks are relevant
- **Zero dependencies** - Pure Zig implementations requiring no external libraries
- **Compile-time polymorphism** - Generic interfaces for algorithm flexibility
- **Memory safe** - Leverages Zig's safety features to prevent buffer overflows and use-after-free
- **Well-audited** - Based on proven implementations with extensive test coverage

**When to use std.crypto:**
- Hashing data for integrity checks, content addressing, or non-cryptographic fingerprinting
- Storing passwords securely with slow, memory-hard hashing functions
- Encrypting data with authenticated encryption to ensure confidentiality and authenticity
- Comparing secrets (MACs, passwords, tokens) without timing side-channels
- Generating cryptographically secure random numbers
- Implementing secure protocols (TLS, SSH, etc.)
- Digital signatures and public-key cryptography

**Related namespaces:**
- `std.Io.randomSecure` - Cryptographically secure random number generation
- `std.crypto.tls` - TLS 1.3 implementation for secure communication
- `std.crypto.Certificate` - X.509 certificate parsing and verification

---

## Core Types

### `SideChannelsMitigations`

Configuration for side-channel attack mitigations (timing attacks, cache-timing attacks).

**Fields:**
- `timing_safe: bool` - Enable constant-time operations
- `memory_hardening: bool` - Enable memory access pattern hardening

**Example:**
```zig
const mitigations = std.crypto.SideChannelsMitigations{
    .timing_safe = true,
    .memory_hardening = true,
};
```

------

### `Certificate`

X.509 certificate parsing and verification support.

**Key nested types:**
- `Bundle` - Collection of trusted root certificates
- `Parsed` - Parsed certificate with validated structure
- `Algorithm` - Cryptographic algorithm identifiers

**Example:**
```zig
const cert_bundle = try std.crypto.Certificate.Bundle.rescan(allocator);
defer cert_bundle.deinit(allocator);
```

------

## Functions

### Core Security Functions

#### `pub fn secureZero(comptime T: type, s: []volatile T) void`

Securely zeros memory, preventing compiler optimizations from removing the operation. Essential for clearing sensitive data.

**Parameters:**
- `T` - Element type (typically `u8`)
- `s` - Volatile slice to zero (must be marked volatile to prevent optimization)

**Use cases:**
- Clearing encryption keys from memory
- Erasing passwords after use
- Cleaning up sensitive temporary buffers

**Example:**
```zig
const std = @import("std");

pub fn processSecret(password: []const u8) !void {
    // Copy password to mutable buffer for processing
    var password_copy: [256]u8 = undefined;
    @memcpy(password_copy[0..password.len], password);

    // ... use password_copy ...

    // Securely erase password from memory
    std.crypto.secureZero(u8, password_copy[0..]);
}
```

------

## Namespaces

### Hash Functions (`std.crypto.hash`)

Cryptographic hash functions for data integrity and content addressing.

**Available algorithms:**
- **SHA-2 family** - `sha2.Sha256`, `sha2.Sha512`, `sha2.Sha384` (widely deployed, NIST standard)
- **SHA-3 family** - `sha3.Sha3_256`, `sha3.Sha3_512` (latest NIST standard, Keccak-based)
- **BLAKE2** - `blake2.Blake2b512`, `blake2.Blake2s256` (fast, secure alternative to SHA-2)
- **BLAKE3** - `Blake3` (extremely fast, parallelizable, modern choice)

**Example:**
```zig
const std = @import("std");

pub fn hashFile(io: std.Io, path: []const u8) ![32]u8 {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var hasher = std.crypto.hash.Blake3.init(.{});
    var file_buffer: [4096]u8 = undefined;
    var reader = file.readerStreaming(io, &file_buffer);
    var chunk: [4096]u8 = undefined;

    while (true) {
  const n = try reader.interface.readSliceShort(&chunk);
  if (n == 0) break;
  hasher.update(chunk[0..n]);
    }

    var hash: [32]u8 = undefined;
    hasher.final(&hash);
    return hash;
}
```

------

### Authenticated Encryption (`std.crypto.aead`)

AEAD (Authenticated Encryption with Associated Data) provides both confidentiality and authenticity.

**Available schemes:**
- **ChaCha20-Poly1305** - Modern, fast, patent-free (recommended for most uses)
- **AES-GCM** - Hardware-accelerated on modern CPUs (Intel AES-NI)
- **AEGIS-128L/256** - Extremely fast, state-of-the-art AEAD
- **AES-OCB** - High performance, single-pass AEAD

**Example:**
```zig
const std = @import("std");
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

pub fn encryptMessage(io: std.Io, plaintext: []const u8, key: [32]u8) !struct {
    ciphertext: []u8,
    nonce: [12]u8,
    tag: [16]u8
} {
    const allocator = std.heap.page_allocator;

    // Generate random nonce (MUST be unique for each message with same key)
    var nonce: [12]u8 = undefined;
    try io.randomSecure(&nonce);

    // Allocate space for ciphertext
    const ciphertext = try allocator.alloc(u8, plaintext.len);
    var tag: [16]u8 = undefined;

    // Encrypt with associated data (empty string in this example)
    ChaCha20Poly1305.encrypt(ciphertext, &tag, plaintext, "", nonce, key);

    return .{
  .ciphertext = ciphertext,
  .nonce = nonce,
  .tag = tag
    };
}

pub fn decryptMessage(
    ciphertext: []const u8,
    nonce: [12]u8,
    tag: [16]u8,
    key: [32]u8
) ![]u8 {
    const allocator = std.heap.page_allocator;
    const plaintext = try allocator.alloc(u8, ciphertext.len);

    // Decrypt and verify authentication tag
    try ChaCha20Poly1305.decrypt(plaintext, ciphertext, tag, "", nonce, key);

    return plaintext;
}
```

------

### Password Hashing (`std.crypto.pwhash`)

Slow, memory-hard functions for deriving keys from passwords.

**Available algorithms:**
- **Argon2** - Winner of Password Hashing Competition (recommended)
- **bcrypt** - Widely deployed, battle-tested
- **scrypt** - Memory-hard, good alternative
- **PBKDF2** - Legacy, avoid for new applications

**Example:**
```zig
const std = @import("std");
const argon2 = std.crypto.pwhash.argon2;

pub fn hashAndVerifyPassword(io: std.Io) !void {
    const allocator = std.heap.page_allocator;
    const password = "correct_horse_battery_staple";

    // Generate random salt
    var salt: [32]u8 = undefined;
    try io.randomSecure(&salt);

    // Hash password (produces PHC format string)
    var hash_buf: [128]u8 = undefined;
    const hash_str = try argon2.strHash(password, .{
  .allocator = allocator,
  .params = argon2.Params.interactive,  // For interactive logins
  .encoding = .phc,
    }, &hash_buf);

    std.debug.print("Password hash: {s}\n", .{hash_str});

    // Verify password
    const valid = try argon2.strVerify(hash_str, password, .{
  .allocator = allocator,
    });

    std.debug.print("Password valid: {}\n", .{valid});
}
```

------

### Constant-Time Operations (`std.crypto.timing_safe`)

Operations resistant to timing side-channel attacks.

**Available functions:**
- `eql` - Constant-time equality comparison
- `compare` - Constant-time ordering comparison
- `add` - Constant-time addition
- `sub` - Constant-time subtraction

**Example:**
```zig
const std = @import("std");

pub fn verifyHMAC(received: [32]u8, computed: [32]u8) bool {
    // Use timing-safe comparison to prevent timing attacks
    return std.crypto.timing_safe.eql([32]u8, received, computed);
}

pub fn compareHashes(a: [32]u8, b: [32]u8) std.math.Order {
    // Compare in constant time
    return std.crypto.timing_safe.compare(u8, &a, &b, .big);
}
```

------

### Digital Signatures (`std.crypto.sign`)

Public-key signature schemes for authentication and non-repudiation.

**Available schemes:**
- **Ed25519** - Fast, secure, modern (recommended for classical cryptography)
- **ECDSA** - Widely deployed with various curves
- **ML-DSA (Dilithium)** - Post-quantum secure signatures (NIST standardized)

**Classical Signature Example (Ed25519):**
```zig
const std = @import("std");
const Ed25519 = std.crypto.sign.Ed25519;

pub fn signAndVerify() !void {
    // Generate key pair
    const seed: [32]u8 = [_]u8{0x42} ** 32;  // Use crypto.random in production!
    const key_pair = try Ed25519.KeyPair.generateDeterministic(seed);

    const message = "Sign this message";

    // Sign message
    const signature = try key_pair.sign(message, null);

    // Verify signature
    try signature.verify(message, key_pair.public_key);

    std.debug.print("Signature verified!\n", .{});
}
```

**Post-Quantum Signature Example (ML-DSA):**
```zig
const std = @import("std");
const mldsa = std.crypto.sign.mldsa;

pub fn postQuantumSignAndVerify() !void {
    // ML-DSA-44: 128-bit security (smallest signatures)
    // ML-DSA-65: 192-bit security (medium signatures)
    // ML-DSA-87: 256-bit security (largest signatures)
    const MLDSA = mldsa.MLDSA44;

    // Generate key pair
    const seed: [32]u8 = [_]u8{0x42} ** 32;  // Use crypto.random in production!
    const key_pair = try MLDSA.KeyPair.generateDeterministic(seed);

    std.debug.print("Public key:  {} bytes\n", .{MLDSA.PublicKey.encoded_length});
    std.debug.print("Signature:   {} bytes\n", .{MLDSA.Signature.encoded_length});

    const message = "Post-quantum secure message";

    // Sign message
    const signature = try key_pair.sign(message, null);

    // Verify signature
    try signature.verify(message, key_pair.public_key);

    // Sign with context for domain separation
    const context = "MyApp-v1";
    const sig_ctx = try key_pair.signWithContext(message, null, context);
    try sig_ctx.verifyWithContext(message, key_pair.public_key, context);

    std.debug.print("Post-quantum signature verified!\n", .{});
}
```

**ML-DSA Security Levels:**
- **ML-DSA-44** - 2420 byte signatures, 128-bit security (NIST Category 2)
- **ML-DSA-65** - 3309 byte signatures, 192-bit security (NIST Category 3)
- **ML-DSA-87** - 4627 byte signatures, 256-bit security (NIST Category 5)

**Note:** ML-DSA signatures are 38-72x larger than Ed25519 (64 bytes) but provide quantum resistance.

**Performance Benchmark Results (1000 iterations, Release-Fast):**

```
📏 Size Comparison
┌───────────┬──────────┬────────────┬────────────┬───────────┬──────────────────┐
│ Parameter │ Security │ Public Key │ Secret Key │ Signature │   vs ML-DSA-44   │
├───────────┼──────────┼────────────┼────────────┼───────────┼──────────────────┤
│ ML-DSA-44 │ 128-bit  │ 1312 B     │ 2560 B     │ 2420 B    │ 1.00x (baseline) │
├───────────┼──────────┼────────────┼────────────┼───────────┼──────────────────┤
│ ML-DSA-65 │ 192-bit  │ 1952 B     │ 4032 B     │ 3309 B    │ 1.37x larger     │
├───────────┼──────────┼────────────┼────────────┼───────────┼──────────────────┤
│ ML-DSA-87 │ 256-bit  │ 2592 B     │ 4896 B     │ 4627 B    │ 1.91x larger     │
└───────────┴──────────┴────────────┴────────────┴───────────┴──────────────────┘

⚡ Performance Results (Typical Hardware)
┌───────────────────┬───────────┬───────────┬───────────┐
│     Operation     │ ML-DSA-44 │ ML-DSA-65 │ ML-DSA-87 │
├───────────────────┼───────────┼───────────┼───────────┤
│ Key Generation    │ 38.73 µs  │ 70.15 µs  │ 98.07 µs  │
├───────────────────┼───────────┼───────────┼───────────┤
│ Sign Message      │ 75.70 µs  │ 119.38 µs │ 126.08 µs │
├───────────────────┼───────────┼───────────┼───────────┤
│ Verify Signature  │ 12.06 µs  │ 14.81 µs  │ 21.75 µs  │
├───────────────────┼───────────┼───────────┼───────────┤
│ Total Sign+Verify │ 87.75 µs  │ 134.19 µs │ 147.83 µs │
└───────────────────┴───────────┴───────────┴───────────┘
```

**Key Insights:**

1. **ML-DSA-44 (Smallest/Fastest)**:
   - 2420-byte signatures (38x larger than Ed25519's 64 bytes)
   - ~88 µs total sign+verify time
   - Best for bandwidth-sensitive applications (blockchain, IoT, mobile)

2. **ML-DSA-65 (Balanced)**:
   - 3309-byte signatures (only 37% larger than ML-DSA-44)
   - ~134 µs total (53% slower but still very fast)
   - Good balance for most general-purpose applications

3. **ML-DSA-87 (Maximum Security)**:
   - 4627-byte signatures (91% larger than ML-DSA-44)
   - ~148 µs total (68% slower but still negligible)
   - Best for long-term document signing and maximum security needs

**Practical Trade-offs:**
- **Size penalty**: Signatures are 38-72x larger than classical Ed25519
- **Speed**: Still extremely fast (~88-148 µs) - negligible for most use cases
- **Benefit**: Quantum-resistant signatures protect against future quantum computers
- **Choice**: Select based on signature size constraints vs security requirements

------

### Post-Quantum Key Encapsulation (`std.crypto.kem.ml_kem`)

ML-KEM (Kyber) is a post-quantum secure Key Encapsulation Mechanism (KEM) for establishing shared secrets. Unlike ML-DSA signatures, ML-KEM has much smaller key sizes, making it practical for real-world use.

**Available security levels:**
- **ML-KEM-512** - 128-bit security, smallest keys
- **ML-KEM-768** - 192-bit security, medium keys
- **ML-KEM-1024** - 256-bit security, largest keys

**Complete Key Exchange Example:**
```zig
const std = @import("std");
const MLKem512 = std.crypto.kem.ml_kem.MLKem512;

pub fn aliceBobKeyExchange(io: std.Io) !void {
    // Alice generates key pair (800-byte public key!)
    const alice_seed: [MLKem512.seed_length]u8 = [_]u8{0xAA} ** MLKem512.seed_length;
    const alice_kp = try MLKem512.KeyPair.generateDeterministic(alice_seed);

    // Alice sends public key to Bob (800 bytes)
    const alice_pk_bytes = alice_kp.public_key.toBytes();

    // Bob receives and deserializes Alice's public key
    const alice_pk = try MLKem512.PublicKey.fromBytes(&alice_pk_bytes);

    // Bob encapsulates: generates shared secret and ciphertext (768 bytes)
    const bob_result = alice_pk.encaps(io);

    // Bob sends ciphertext back to Alice (768 bytes)

    // Alice decapsulates using her secret key
    const alice_shared = try alice_kp.secret_key.decaps(&bob_result.ciphertext);

    // Both now have the same 32-byte shared secret!
    std.debug.print("Shared secret established: {} bytes\n", .{alice_shared.len});
}
```

**ML-KEM Key Sizes (much smaller than ML-DSA!):**

| Scheme | Public Key | Secret Key | Ciphertext | Security |
|--------|-----------|-----------|------------|----------|
| ML-KEM-512 | 800 B | 1632 B | 768 B | 128-bit |
| ML-KEM-768 | 1184 B | 2400 B | 1088 B | 192-bit |
| ML-KEM-1024 | 1568 B | 3168 B | 1568 B | 256-bit |

**Comparison to Classical X25519:**
- X25519: 32-byte public key (25x smaller)
- ML-KEM-512: 800-byte public key (25x larger than X25519)
- Trade-off: Quantum resistance for ~1 kB overhead

**Note:** ML-KEM is practical for real-world deployment (under 1 kB public keys), unlike some other post-quantum schemes with multi-MB keys.

**Performance Benchmark Results (1000 iterations, Release-Fast):**

```
📏 Size Comparison
┌─────────────┬──────────┬────────────┬────────────┬────────────┬────────────────────┐
│  Parameter  │ Security │ Public Key │ Secret Key │ Ciphertext │ Performance vs 512 │
├─────────────┼──────────┼────────────┼────────────┼────────────┼────────────────────┤
│ ML-KEM-512  │ 128-bit  │ 800 B      │ 1632 B     │ 768 B      │ 1.00x (baseline)   │
├─────────────┼──────────┼────────────┼────────────┼────────────┼────────────────────┤
│ ML-KEM-768  │ 192-bit  │ 1184 B     │ 2400 B     │ 1088 B     │ 1.13x slower       │
├─────────────┼──────────┼────────────┼────────────┼────────────┼────────────────────┤
│ ML-KEM-1024 │ 256-bit  │ 1568 B     │ 3168 B     │ 1568 B     │ 1.51x slower       │
└─────────────┴──────────┴────────────┴────────────┴────────────┴────────────────────┘

⚡ Performance Results (Typical Hardware)
┌────────────────┬────────────┬────────────┬─────────────┐
│   Operation    │ ML-KEM-512 │ ML-KEM-768 │ ML-KEM-1024 │
├────────────────┼────────────┼────────────┼─────────────┤
│ Key Generation │ 12.76 µs   │ 17.18 µs   │ 24.70 µs    │
├────────────────┼────────────┼────────────┼─────────────┤
│ Encapsulation  │ 7.07 µs    │ 6.74 µs    │ 8.18 µs     │
├────────────────┼────────────┼────────────┼─────────────┤
│ Decapsulation  │ 10.62 µs   │ 10.51 µs   │ 12.94 µs    │
├────────────────┼────────────┼────────────┼─────────────┤
│ Total Exchange │ 30.45 µs   │ 34.43 µs   │ 45.82 µs    │
└────────────────┴────────────┴────────────┴─────────────┘
```

**Key Insights:**

1. **ML-KEM-768 (NIST Recommended Default)**:
   - Only 13% slower than ML-KEM-512 (~34 µs vs ~30 µs)
   - 48% larger public keys (1184 B vs 800 B)
   - Provides 192-bit post-quantum security (NIST Category 3)
   - **Best balance** for most applications

2. **ML-KEM-512 (Smallest/Fastest)**:
   - Full key exchange in ~30 microseconds
   - Public keys under 1 kB (800 bytes)
   - Still provides 128-bit post-quantum security (NIST Category 1)
   - Use when size/speed are critical constraints

3. **ML-KEM-1024 (Maximum Security)**:
   - Only 51% slower than ML-KEM-512 (~46 µs vs ~30 µs)
   - Provides 256-bit post-quantum security (NIST Category 5)
   - Future-proof for long-term data protection
   - Use for maximum security margin

**Practical Deployment Considerations:**
- ML-KEM-512 is ~25x larger than classical X25519 (800 B vs 32 B)
- But 1000x+ smaller than some PQ schemes (Goppa McEliece: 1 MB)
- Performance overhead is negligible: ~30-45 µs total
- All variants produce same 32-byte shared secret

------

### Key Derivation (`std.crypto.kdf`)

Derive multiple keys from a single master key or password.

**Available schemes:**
- **HKDF** - HMAC-based KDF (RFC 5869)
- **PBKDF2** - Password-based KDF (legacy, prefer Argon2 for passwords)

------

## Usage Patterns

### Pattern 1: Secure Password Storage

```zig
const std = @import("std");
const argon2 = std.crypto.pwhash.argon2;

pub fn registerUser(username: []const u8, password: []const u8) ![]u8 {
    const allocator = std.heap.page_allocator;

    // Hash password with Argon2
    var hash_buf: [128]u8 = undefined;
    const hash_str = try argon2.strHash(password, .{
  .allocator = allocator,
  .params = argon2.Params.interactive,
  .encoding = .phc,
    }, &hash_buf);

    // Store hash_str in database associated with username
    const stored_hash = try allocator.dupe(u8, hash_str);
    std.debug.print("User {s} registered with hash: {s}\n", .{ username, stored_hash });

    return stored_hash;
}

pub fn loginUser(username: []const u8, password: []const u8, stored_hash: []const u8) !bool {
    const allocator = std.heap.page_allocator;

    // Verify password against stored hash
    const valid = try argon2.strVerify(stored_hash, password, .{
  .allocator = allocator,
    });

    if (valid) {
  std.debug.print("User {s} logged in successfully\n", .{username});
    } else {
  std.debug.print("Invalid password for user {s}\n", .{username});
    }

    return valid;
}
```

**Explanation:**
1. `registerUser` hashes password using Argon2 with safe defaults
2. PHC format string includes salt, parameters, and hash
3. `loginUser` verifies password in constant time
4. No need to store salt separately - it's in the PHC string

------

### Pattern 2: Message Encryption and Authentication

```zig
const std = @import("std");
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

const EncryptedMessage = struct {
    nonce: [12]u8,
    ciphertext: []u8,
    tag: [16]u8,
};

pub fn encryptAndSend(io: std.Io, plaintext: []const u8, shared_key: [32]u8) !EncryptedMessage {
    const allocator = std.heap.page_allocator;

    // Generate unique nonce
    var nonce: [12]u8 = undefined;
    try io.randomSecure(&nonce);

    // Encrypt message
    const ciphertext = try allocator.alloc(u8, plaintext.len);
    var tag: [16]u8 = undefined;

    ChaCha20Poly1305.encrypt(ciphertext, &tag, plaintext, "", nonce, shared_key);

    return EncryptedMessage{
  .nonce = nonce,
  .ciphertext = ciphertext,
  .tag = tag,
    };
}

pub fn receiveAndDecrypt(msg: EncryptedMessage, shared_key: [32]u8) ![]u8 {
    const allocator = std.heap.page_allocator;

    const plaintext = try allocator.alloc(u8, msg.ciphertext.len);

    // Decrypt and verify
    ChaCha20Poly1305.decrypt(
  plaintext,
  msg.ciphertext,
  msg.tag,
  "",
  msg.nonce,
  shared_key
    ) catch |err| {
  allocator.free(plaintext);
  return error.AuthenticationFailed;
    };

    return plaintext;
}
```

**Explanation:**
1. Each message gets a unique random nonce
2. ChaCha20-Poly1305 encrypts and authenticates in one operation
3. Decryption fails if ciphertext or tag is tampered with
4. Associated data (empty here) can include message metadata

------

### Pattern 3: File Integrity Verification

```zig
const std = @import("std");
const Blake3 = std.crypto.hash.Blake3;

pub fn computeFileHash(io: std.Io, path: []const u8) ![32]u8 {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var hasher = Blake3.init(.{});
    var file_buffer: [8192]u8 = undefined;
    var reader = file.readerStreaming(io, &file_buffer);
    var chunk: [8192]u8 = undefined;

    while (true) {
  const bytes_read = try reader.interface.readSliceShort(&chunk);
  if (bytes_read == 0) break;
  hasher.update(chunk[0..bytes_read]);
    }

    var hash: [32]u8 = undefined;
    hasher.final(&hash);
    return hash;
}

pub fn verifyFileIntegrity(io: std.Io, path: []const u8, expected_hash: [32]u8) !bool {
    const actual_hash = try computeFileHash(io, path);

    // Timing-safe comparison
    return std.crypto.timing_safe.eql([32]u8, actual_hash, expected_hash);
}

pub fn checksumDirectory(io: std.Io, dir_path: []const u8) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
  if (entry.kind == .file) {
      const full_path = try std.fs.path.join(
          std.heap.page_allocator,
          &.{ dir_path, entry.name }
      );
      defer std.heap.page_allocator.free(full_path);

      const hash = try computeFileHash(full_path);
      std.debug.print("{s}: ", .{entry.name});
      for (hash) |byte| {
          std.debug.print("{x:0>2}", .{byte});
      }
      std.debug.print("\n", .{});
  }
    }
}
```

**Explanation:**
1. BLAKE3 provides fast, secure hashing
2. Incremental hashing handles large files efficiently
3. Timing-safe comparison prevents hash-based timing attacks
4. Can compute checksums for entire directories

------

### Pattern 4: Key Derivation for Multiple Purposes

```zig
const std = @import("std");
const hkdf = std.crypto.kdf.hkdf;
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn deriveKeys(master_key: [32]u8) !struct {
    encryption_key: [32]u8,
    mac_key: [32]u8,
    iv_key: [16]u8,
} {
    var encryption_key: [32]u8 = undefined;
    var mac_key: [32]u8 = undefined;
    var iv_key: [16]u8 = undefined;

    // Derive encryption key
    hkdf.Hkdf(Sha256).extract(&encryption_key, &master_key, "encryption");

    // Derive MAC key
    hkdf.Hkdf(Sha256).extract(&mac_key, &master_key, "authentication");

    // Derive IV generation key
    hkdf.Hkdf(Sha256).extract(&iv_key, &master_key, "iv");

    return .{
  .encryption_key = encryption_key,
  .mac_key = mac_key,
  .iv_key = iv_key,
    };
}
```

**Explanation:**
1. HKDF derives multiple independent keys from one master key
2. Context strings ensure key separation
3. Each derived key serves a specific purpose
4. Changing context string produces different key

------

## Types and Constants

### User-Facing Types

**`SideChannelsMitigations` (struct)**
```zig
pub const SideChannelsMitigations = struct {
    timing_safe: bool,
    memory_hardening: bool,
};
```
Configuration for side-channel attack mitigations.

------

**`Certificate` (struct)**
X.509 certificate parsing and validation support. See `std.crypto.Certificate` documentation for details.

------

### Constants

**`default_side_channels_mitigations: SideChannelsMitigations`**

Default configuration for side-channel mitigations (enabled by default for security).

------

## Error Sets

### Cryptographic Errors

**Common across crypto operations:**
- `error.AuthenticationFailed` - AEAD authentication tag verification failed
- `error.IdentityElement` - Public key is identity element (invalid)
- `error.NonCanonical` - Encoded value is not in canonical form
- `error.SignatureVerificationFailed` - Digital signature is invalid
- `error.WeakPublicKey` - Public key is cryptographically weak
- `error.InvalidEncoding` - Data encoding is malformed

**Password hashing errors:**
- `error.PasswordVerificationFailed` - Password does not match hash
- `error.WeakParametersError` - Hash parameters are too weak
- `error.OutputTooLongError` - Requested output length exceeds maximum

------

## Debug Checklist

✅ **Never reuse nonces** - Each encryption with same key must use unique nonce

✅ **Use crypto.random for keys/nonces** - Never hardcode or use weak randomness

✅ **Constant-time comparison for secrets** - Use `timing_safe.eql()` for MACs, tokens, passwords

✅ **Clear sensitive data** - Use `secureZero()` to erase keys, passwords from memory

✅ **Verify all authentication tags** - Never ignore AEAD decryption errors

✅ **Use password hashing for passwords** - Never use fast hashes (SHA-256) for passwords

✅ **Check key lengths** - Many algorithms require specific key/nonce sizes

✅ **Handle error unions** - Crypto operations can fail; always check errors

✅ **Store salts with hashes** - Use PHC format or store salt alongside hash

✅ **Validate input sizes** - Check buffer lengths before crypto operations

------

## Performance Tips

1. **Choose algorithms based on hardware** - Use AES-GCM on CPUs with AES-NI, ChaCha20-Poly1305 otherwise:
   ```zig
   const hasAESNI = std.Target.x86.featureSetHas(builtin.cpu.features, .aes);
   const AEAD = if (hasAESNI)
 std.crypto.aead.aes_gcm.Aes256Gcm
   else
 std.crypto.aead.chacha_poly.ChaCha20Poly1305;
   ```

2. **Use BLAKE3 for high-performance hashing** - Significantly faster than SHA-256 with parallel processing:
   ```zig
   // BLAKE3 is 10x+ faster than SHA-256 on large files
   var hasher = std.crypto.hash.Blake3.init(.{});
   hasher.update(large_data);
   ```

3. **Reuse hash contexts for incremental hashing** - Avoid reallocating for streaming data:
   ```zig
   var hasher = Sha256.init(.{});
   for (chunks) |chunk| {
 hasher.update(chunk);  // Incremental
   }
   hasher.final(&hash);
   ```

4. **Pre-allocate buffers for crypto operations** - Avoid allocations in hot paths:
   ```zig
   var ciphertext_buf: [1024]u8 = undefined;  // Stack allocation
   ChaCha20Poly1305.encrypt(&ciphertext_buf, &tag, plaintext, "", nonce, key);
   ```

5. **Batch verify signatures when possible** - Some schemes support efficient batch verification

6. **Use appropriate Argon2 parameters** - `interactive` for logins, `moderate` for file encryption, `sensitive` for high-security:
   ```zig
   const params = argon2.Params.interactive;  // Fast for user login
   // vs
   const params = argon2.Params.sensitive;    // Slow for high-security
   ```

7. **Consider memory constraints for pwhash** - Argon2 uses significant RAM; tune for your environment:
   ```zig
   const params = argon2.Params{
 .t = 3,      // Time cost (iterations)
 .m = 65536,  // Memory cost (64 MB)
 .p = 4,      // Parallelism
   };
   ```

8. **Choose signature scheme based on requirements** - Ed25519 for speed/size, ML-DSA for quantum resistance:
   ```zig
   // Ed25519: 64-byte signatures, fast, quantum-vulnerable
   const ClassicalSig = std.crypto.sign.Ed25519;

   // ML-DSA-44: 2420-byte signatures, slower, quantum-resistant
   const PostQuantumSig = std.crypto.sign.mldsa.MLDSA44;

   // Use ML-DSA for long-term security (>10 years)
   // Use Ed25519 for current applications with size constraints
   ```

------

## See Also

- **std.Io.randomSecure** - Cryptographically secure random number generation
- **std.crypto.tls** - TLS 1.3 implementation for secure network communication
- **std.crypto.Certificate** - X.509 certificate handling for TLS/PKI
- **std.mem** - Memory utilities (for non-cryptographic comparisons)
- **std.hash** - Fast non-cryptographic hashing (CRC32, Wyhash)
