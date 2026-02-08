# std.crypto.sign

Digital signature schemes for authentication, integrity, and non-repudiation. Supports both classical (Ed25519, ECDSA) and post-quantum (ML-DSA/Dilithium) algorithms.

## Common Interface

All signature types share a similar pattern:

```zig
// Generate key pair
const key_pair = try Scheme.KeyPair.generateDeterministic(seed);
// Or from random: const key_pair = Scheme.KeyPair.generate(io);

// Sign a message
const signature = try key_pair.sign(message, null);

// Verify a signature
try signature.verify(message, key_pair.public_key);
// Returns error.SignatureVerificationFailed if invalid
```

**Common types and methods:**

| Type/Method | Description |
|-------------|-------------|
| `KeyPair` | Contains `.public_key` and `.secret_key` |
| `KeyPair.generateDeterministic(seed)` | Generate from a 32-byte seed |
| `KeyPair.generate(io)` | Generate from cryptographic randomness |
| `key_pair.sign(msg, context)` | Sign a message, returns `Signature` |
| `signature.verify(msg, public_key)` | Verify signature against public key |
| `Signature.toBytes()` / `fromBytes()` | Serialize/deserialize signatures |
| `PublicKey.toBytes()` / `fromBytes()` | Serialize/deserialize public keys |

## Namespaces

### `Ed25519`

Edwards-curve Digital Signature Algorithm on Curve25519. Fast, secure, compact signatures. The recommended classical signature scheme.

- **Public key:** 32 bytes
- **Secret key:** 64 bytes (includes public key)
- **Signature:** 64 bytes
- **Security:** ~128-bit classical

```zig
const Ed25519 = std.crypto.sign.Ed25519;

// Generate key pair from seed
const seed: [32]u8 = ...; // Use std.crypto.random.bytes() in production
const key_pair = try Ed25519.KeyPair.generateDeterministic(seed);

// Sign
const message = "Authenticate this message";
const signature = try key_pair.sign(message, null);

// Verify (anyone with the public key can verify)
try signature.verify(message, key_pair.public_key);

// Serialize for transmission
const sig_bytes = signature.toBytes();   // [64]u8
const pk_bytes = key_pair.public_key.toBytes();  // [32]u8

// Deserialize
const pk = try Ed25519.PublicKey.fromBytes(pk_bytes);
const sig = Ed25519.Signature.fromBytes(sig_bytes);
try sig.verify(message, pk);
```

### `ecdsa`

Elliptic Curve Digital Signature Algorithm. Widely deployed in TLS, SSH, and cryptocurrency. Use Ed25519 for new designs unless ECDSA is required for interoperability.

**Available curves:**

| Type | Curve | Key | Signature | Notes |
|------|-------|-----|-----------|-------|
| `EcdsaP256Sha256` | P-256 | 32 B | 64 B | NIST standard, TLS |
| `EcdsaP384Sha384` | P-384 | 48 B | 96 B | Higher security margin |
| `EcdsaSecp256k1Sha256` | secp256k1 | 32 B | 64 B | Bitcoin, Ethereum |

```zig
const Ecdsa = std.crypto.sign.ecdsa.EcdsaP256Sha256;

const key_pair = try Ecdsa.KeyPair.generateDeterministic(seed);
const signature = try key_pair.sign(message, null);
try signature.verify(message, key_pair.public_key);
```

### `mldsa`

ML-DSA (Module-Lattice Digital Signature Algorithm), formerly known as Dilithium. NIST-standardized post-quantum signature scheme resistant to quantum computer attacks.

**Available security levels:**

| Type | Public Key | Signature | Security | NIST Category |
|------|-----------|-----------|----------|---------------|
| `MLDSA44` | 1312 B | 2420 B | 128-bit | Category 2 |
| `MLDSA65` | 1952 B | 3309 B | 192-bit | Category 3 |
| `MLDSA87` | 2592 B | 4627 B | 256-bit | Category 5 |

```zig
const MLDSA44 = std.crypto.sign.mldsa.MLDSA44;

// Generate key pair
const seed: [32]u8 = ...; // Use std.crypto.random.bytes() in production
const key_pair = try MLDSA44.KeyPair.generateDeterministic(seed);

// Sign
const signature = try key_pair.sign("post-quantum message", null);

// Verify
try signature.verify("post-quantum message", key_pair.public_key);

// Sign with context for domain separation
const sig_ctx = try key_pair.signWithContext("message", null, "MyApp-v1");
try sig_ctx.verifyWithContext("message", key_pair.public_key, "MyApp-v1");

// Serialization
const pk_bytes = key_pair.public_key.toBytes();  // [1312]u8
const sig_bytes = signature.toBytes();             // [2420]u8
```

**ML-DSA vs Ed25519 comparison:**

| Property | Ed25519 | ML-DSA-44 | ML-DSA-65 |
|----------|---------|-----------|-----------|
| Signature size | 64 B | 2420 B | 3309 B |
| Public key | 32 B | 1312 B | 1952 B |
| Sign time | ~5 µs | ~76 µs | ~119 µs |
| Verify time | ~8 µs | ~12 µs | ~15 µs |
| Quantum resistant | No | Yes | Yes |

## Scheme Selection Guide

| Need | Recommendation |
|------|---------------|
| General purpose, compact | **Ed25519** (64-byte sigs, fast) |
| Quantum resistance | **ML-DSA-44** (smallest PQ sigs) |
| Maximum PQ security | **ML-DSA-87** (256-bit PQ security) |
| TLS/SSH interoperability | **ECDSA P-256** |
| Cryptocurrency | **ECDSA secp256k1** |
| Long-term documents | **ML-DSA-65** (good balance of size + PQ security) |

## See Also

- **std.crypto.dh** - Key exchange (X25519)
- **std.crypto.kem** - Post-quantum key encapsulation (ML-KEM)
- **std.crypto.auth** - Symmetric authentication (HMAC)
