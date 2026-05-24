# std.crypto.dh

Diffie-Hellman key exchange functions. Allows two parties to establish a shared secret over an insecure channel without prior shared knowledge.

## Namespaces

### `X25519`

X25519 Elliptic Curve Diffie-Hellman (ECDH) on Curve25519. The recommended classical key exchange mechanism. Fast, secure, and widely deployed in TLS 1.3, WireGuard, Signal, and SSH.

- **Public key:** 32 bytes
- **Secret key:** 32 bytes
- **Shared secret:** 32 bytes
- **Security:** ~128-bit classical

**Key Types:**

| Type | Size | Description |
|------|------|-------------|
| `KeyPair` | 64 B | Secret key + public key |
| `PublicKey` | 32 B | Public component for exchange |
| `SecretKey` | 32 B | Private component, never shared |

**Methods:**

| Method | Description |
|--------|-------------|
| `KeyPair.generateDeterministic(seed)` | Generate from a 32-byte seed |
| `KeyPair.generate(io)` | Generate from cryptographic randomness |
| `KeyPair.fromSecretKey(sk)` | Derive key pair from existing secret key |
| `scalarmult(pk, sk)` | Compute shared secret from public + secret key |

```zig
const X25519 = std.crypto.dh.X25519;

// === Key Exchange Protocol ===

// Alice generates her key pair
const alice_seed: [32]u8 = ...; // Use io.randomSecure() in production
const alice_kp = try X25519.KeyPair.generateDeterministic(alice_seed);

// Bob generates his key pair
const bob_seed: [32]u8 = ...;
const bob_kp = try X25519.KeyPair.generateDeterministic(bob_seed);

// Alice and Bob exchange public keys over the network...

// Alice computes shared secret using Bob's public key
const alice_shared = try X25519.scalarmult(bob_kp.public_key, alice_kp.secret_key);

// Bob computes shared secret using Alice's public key
const bob_shared = try X25519.scalarmult(alice_kp.public_key, bob_kp.secret_key);

// Both arrive at the same shared secret!
// alice_shared == bob_shared

// Use the shared secret as input to a KDF (never use it directly as a key)
const session_key = hkdf.extract(&prk, &alice_shared, "session-key");
```

**Errors:**

| Error | Meaning |
|-------|---------|
| `IdentityElementError` | Public key is the identity point (all zeros) - reject the peer |
| `WeakPublicKeyError` | Public key is from a weak subgroup - reject the peer |

## Security Notes

- **Always validate public keys** - `scalarmult` returns errors for weak/identity keys
- **Never use the raw shared secret as a key** - always derive keys through a KDF (HKDF)
- **X25519 is not quantum-resistant** - for post-quantum key exchange, see `std.crypto.kem.ml_kem`
- **Ephemeral keys recommended** - generate fresh key pairs per session for forward secrecy

## Typical Protocol Pattern

```zig
const X25519 = std.crypto.dh.X25519;
const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;

pub fn establishSession(peer_public_key: [32]u8, io: std.Io) !struct {
    our_public_key: [32]u8,
    encryption_key: [32]u8,
} {
    // Generate ephemeral key pair
    const our_kp = X25519.KeyPair.generate(io);

    // Compute shared secret
    const shared = try X25519.scalarmult(peer_public_key, our_kp.secret_key);

    // Derive encryption key via HKDF
    const prk = Hkdf.extract("", &shared);
    var encryption_key: [32]u8 = undefined;
    Hkdf.expand(&encryption_key, prk, "encryption", .{});

    return .{
  .our_public_key = our_kp.public_key,
  .encryption_key = encryption_key,
    };
}
```

## See Also

- **std.crypto.kem.ml_kem** - Post-quantum key encapsulation (ML-KEM/Kyber)
- **std.crypto.kdf** - Key derivation functions (HKDF) for deriving session keys
- **std.crypto.sign** - Digital signatures for authentication
- **std.crypto.ecc** - Low-level elliptic curve arithmetic
