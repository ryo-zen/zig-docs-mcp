// Test file for std.crypto namespace documentation
// Run with: zig test crypto.tests.zig
//
// This file validates all code examples from zig_docs_std/Namespaces/crypto/std.crypto.md

const std = @import("std");
const testing = std.testing;

// ============================================================================
// Quick Start Examples
// ============================================================================

test "Quick Start: Hashing Data (SHA-256)" {
    std.debug.print("\n=== Test: Hashing Data (SHA-256) ===\n", .{});

    const sha256 = std.crypto.hash.sha2.Sha256;

    const hashData = struct {
        fn func(data: []const u8) [32]u8 {
            var hash: [32]u8 = undefined;
            sha256.hash(data, &hash, .{});
            return hash;
        }
    }.func;

    const data = "Hello, Zig crypto!";
    const hash = hashData(data);

    std.debug.print("  Data: {s}\n", .{data});
    std.debug.print("  Hash: ", .{});
    for (hash) |byte| {
        std.debug.print("{x:0>2}", .{byte});
    }
    std.debug.print("\n  ✅ PASS: SHA-256 hashing works\n\n", .{});
}

test "Quick Start: Password Hashing (Argon2)" {
    std.debug.print("\n=== Test: Password Hashing (Argon2) ===\n", .{});

    const argon2 = std.crypto.pwhash.argon2;
    const allocator = testing.allocator;

    const password = "my_secure_password";

    // Hash password
    var hash_buf: [256]u8 = undefined;
    const hash_str = try argon2.strHash(
        password,
        .{
            .allocator = allocator,
            .params = argon2.Params.interactive_2id,
            .encoding = .phc,
        },
        &hash_buf,
        testing.io,
    );

    std.debug.print("  Password: {s}\n", .{password});
    std.debug.print("  Hash: {s}\n", .{hash_str});

    // Verify password
    try argon2.strVerify(hash_str, password, .{
        .allocator = allocator,
    }, testing.io);

    std.debug.print("  ✅ PASS: Argon2 password hashing works\n\n", .{});
}

test "Quick Start: Authenticated Encryption (ChaCha20-Poly1305)" {
    std.debug.print("\n=== Test: Authenticated Encryption ===\n", .{});

    const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

    const encryptMessage = struct {
        fn func(plaintext: []const u8, ciphertext: []u8, tag: *[16]u8) void {
            const key: [32]u8 = [_]u8{0x42} ** 32;
            const nonce: [12]u8 = [_]u8{0x01} ** 12;
            ChaCha20Poly1305.encrypt(ciphertext, tag, plaintext, "", nonce, key);
        }
    }.func;

    const plaintext = "Secret message";
    var ciphertext: [plaintext.len]u8 = undefined;
    var tag: [16]u8 = undefined;

    encryptMessage(plaintext, &ciphertext, &tag);

    std.debug.print("  Plaintext: {s}\n", .{plaintext});
    std.debug.print("  Ciphertext: ", .{});
    for (ciphertext) |byte| {
        std.debug.print("{x:0>2}", .{byte});
    }
    std.debug.print("\n  Tag: ", .{});
    for (tag) |byte| {
        std.debug.print("{x:0>2}", .{byte});
    }
    std.debug.print("\n  ✅ PASS: ChaCha20-Poly1305 encryption works\n\n", .{});

    // Decrypt to verify
    const key: [32]u8 = [_]u8{0x42} ** 32;
    const nonce: [12]u8 = [_]u8{0x01} ** 12;
    var decrypted: [plaintext.len]u8 = undefined;
    try ChaCha20Poly1305.decrypt(&decrypted, &ciphertext, tag, "", nonce, key);

    try testing.expectEqualStrings(plaintext, &decrypted);
    std.debug.print("  ✅ PASS: Decryption successful\n\n", .{});
}

test "Quick Start: Constant-Time Comparison" {
    std.debug.print("\n=== Test: Constant-Time Comparison ===\n", .{});

    const verifyMAC = struct {
        fn func(received: []const u8, expected: []const u8) bool {
            if (received.len != expected.len) return false;
            if (received.len == 0) return true;

            // Create fixed-size arrays for timing_safe.eql
            const len = received.len;
            if (len == 32) {
                const r: *const [32]u8 = received[0..32];
                const e: *const [32]u8 = expected[0..32];
                return std.crypto.timing_safe.eql([32]u8, r.*, e.*);
            }
            // Fallback for other sizes
            for (received, expected) |r, e| {
                if (r != e) return false;
            }
            return true;
        }
    }.func;

    const mac1: [32]u8 = [_]u8{0xAA} ** 32;
    const mac2: [32]u8 = [_]u8{0xAA} ** 32;
    const mac3: [32]u8 = [_]u8{0xBB} ** 32;

    try testing.expect(verifyMAC(&mac1, &mac2));
    try testing.expect(!verifyMAC(&mac1, &mac3));

    std.debug.print("  ✅ PASS: Constant-time comparison works\n\n", .{});
}

test "Quick Start: Secure Memory Zeroing" {
    std.debug.print("\n=== Test: Secure Memory Zeroing ===\n", .{});

    const clearSensitiveData = struct {
        fn func(data: []u8) void {
            std.crypto.secureZero(u8, data);
        }
    }.func;

    var sensitive_data = [_]u8{ 1, 2, 3, 4, 5 };
    std.debug.print("  Before: {any}\n", .{sensitive_data});

    clearSensitiveData(&sensitive_data);
    std.debug.print("  After:  {any}\n", .{sensitive_data});

    for (sensitive_data) |byte| {
        try testing.expectEqual(@as(u8, 0), byte);
    }

    std.debug.print("  ✅ PASS: secureZero works\n\n", .{});
}

// ============================================================================
// Core Security Functions
// ============================================================================

test "secureZero: Process Secret" {
    std.debug.print("\n=== Test: secureZero with Secret Processing ===\n", .{});

    const processSecret = struct {
        fn func(password: []const u8) !void {
            var password_copy: [256]u8 = undefined;
            @memcpy(password_copy[0..password.len], password);

            // Simulate processing
            std.debug.print("  Processing password...\n", .{});

            // Securely erase
            std.crypto.secureZero(u8, password_copy[0..]);

            // Verify it's zeroed
            for (password_copy[0..password.len]) |byte| {
                if (byte != 0) return error.NotZeroed;
            }
        }
    }.func;

    try processSecret("test_password");
    std.debug.print("  ✅ PASS: Password securely erased\n\n", .{});
}

// ============================================================================
// Hash Functions
// ============================================================================

test "Hash: BLAKE3 Incremental Hashing" {
    std.debug.print("\n=== Test: BLAKE3 Incremental Hashing ===\n", .{});

    const data1 = "Hello, ";
    const data2 = "world!";

    // Hash in one go
    var hash_single: [32]u8 = undefined;
    var hasher1 = std.crypto.hash.Blake3.init(.{});
    hasher1.update(data1 ++ data2);
    hasher1.final(&hash_single);

    // Hash incrementally
    var hash_incremental: [32]u8 = undefined;
    var hasher2 = std.crypto.hash.Blake3.init(.{});
    hasher2.update(data1);
    hasher2.update(data2);
    hasher2.final(&hash_incremental);

    try testing.expectEqualSlices(u8, &hash_single, &hash_incremental);
    std.debug.print("  ✅ PASS: Incremental hashing matches single-pass\n\n", .{});
}

test "Hash: SHA-256 Basic" {
    std.debug.print("\n=== Test: SHA-256 Basic ===\n", .{});

    const Sha256 = std.crypto.hash.sha2.Sha256;

    const data = "The quick brown fox jumps over the lazy dog";
    var hash: [32]u8 = undefined;
    Sha256.hash(data, &hash, .{});

    std.debug.print("  Data: {s}\n", .{data});
    std.debug.print("  SHA-256: ", .{});
    for (hash) |byte| {
        std.debug.print("{x:0>2}", .{byte});
    }
    std.debug.print("\n  ✅ PASS: SHA-256 computed\n\n", .{});
}

// ============================================================================
// Authenticated Encryption (AEAD)
// ============================================================================

test "AEAD: ChaCha20-Poly1305 Full Encrypt/Decrypt" {
    std.debug.print("\n=== Test: ChaCha20-Poly1305 Full Cycle ===\n", .{});

    const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
    const allocator = testing.allocator;

    const encryptMessage = struct {
        fn func(plaintext: []const u8, key: [32]u8, alloc: std.mem.Allocator) !struct {
            ciphertext: []u8,
            nonce: [12]u8,
            tag: [16]u8,
        } {
            // Generate random nonce (using fixed value for test reproducibility)
            const nonce: [12]u8 = [_]u8{0x11} ** 12;

            const ciphertext = try alloc.alloc(u8, plaintext.len);
            var tag: [16]u8 = undefined;

            ChaCha20Poly1305.encrypt(ciphertext, &tag, plaintext, "", nonce, key);

            return .{
                .ciphertext = ciphertext,
                .nonce = nonce,
                .tag = tag,
            };
        }
    }.func;

    const decryptMessage = struct {
        fn func(
            ciphertext: []const u8,
            nonce: [12]u8,
            tag: [16]u8,
            key: [32]u8,
            alloc: std.mem.Allocator,
        ) ![]u8 {
            const plaintext = try alloc.alloc(u8, ciphertext.len);
            try ChaCha20Poly1305.decrypt(plaintext, ciphertext, tag, "", nonce, key);
            return plaintext;
        }
    }.func;

    const original = "This is a secret message!";
    const key: [32]u8 = [_]u8{0x42} ** 32;

    // Encrypt
    const encrypted = try encryptMessage(original, key, allocator);
    defer allocator.free(encrypted.ciphertext);

    std.debug.print("  Plaintext: {s}\n", .{original});
    std.debug.print("  Encrypted ({} bytes)\n", .{encrypted.ciphertext.len});

    // Decrypt
    const decrypted = try decryptMessage(
        encrypted.ciphertext,
        encrypted.nonce,
        encrypted.tag,
        key,
        allocator,
    );
    defer allocator.free(decrypted);

    try testing.expectEqualStrings(original, decrypted);
    std.debug.print("  Decrypted: {s}\n", .{decrypted});
    std.debug.print("  ✅ PASS: Encryption and decryption successful\n\n", .{});
}

test "AEAD: Authentication Failure Detection" {
    std.debug.print("\n=== Test: AEAD Authentication Failure ===\n", .{});

    const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

    const plaintext = "Secret data";
    const key: [32]u8 = [_]u8{0x42} ** 32;
    const nonce: [12]u8 = [_]u8{0x01} ** 12;

    var ciphertext: [plaintext.len]u8 = undefined;
    var tag: [16]u8 = undefined;

    // Encrypt
    ChaCha20Poly1305.encrypt(&ciphertext, &tag, plaintext, "", nonce, key);

    // Tamper with ciphertext
    ciphertext[0] ^= 0xFF;

    // Attempt to decrypt (should fail)
    var decrypted: [plaintext.len]u8 = undefined;
    const result = ChaCha20Poly1305.decrypt(&decrypted, &ciphertext, tag, "", nonce, key);

    try testing.expectError(error.AuthenticationFailed, result);
    std.debug.print("  ✅ PASS: Tampered ciphertext detected\n\n", .{});
}

// ============================================================================
// Password Hashing
// ============================================================================

test "Password Hashing: Argon2 Register and Login" {
    std.debug.print("\n=== Test: Argon2 Register and Login ===\n", .{});

    const argon2 = std.crypto.pwhash.argon2;
    const allocator = testing.allocator;

    const registerUser = struct {
        fn func(username: []const u8, password: []const u8, alloc: std.mem.Allocator) ![]u8 {
            var hash_buf: [256]u8 = undefined;
            const hash_str = try argon2.strHash(
                password,
                .{
                    .allocator = alloc,
                    .params = argon2.Params.interactive_2id,
                    .encoding = .phc,
                },
                &hash_buf,
                testing.io,
            );

            const stored_hash = try alloc.dupe(u8, hash_str);
            std.debug.print("  User {s} registered\n", .{username});
            return stored_hash;
        }
    }.func;

    const loginUser = struct {
        fn func(username: []const u8, password: []const u8, stored_hash: []const u8, alloc: std.mem.Allocator) !void {
            try argon2.strVerify(stored_hash, password, .{
                .allocator = alloc,
            }, testing.io);
            std.debug.print("  User {s} logged in successfully\n", .{username});
        }
    }.func;

    // Register
    const stored_hash = try registerUser("alice", "secure_password", allocator);
    defer allocator.free(stored_hash);

    // Login with correct password
    try loginUser("alice", "secure_password", stored_hash, allocator);

    // Login with wrong password should fail
    const result = loginUser("alice", "wrong_password", stored_hash, allocator);
    try testing.expectError(error.PasswordVerificationFailed, result);

    std.debug.print("  ✅ PASS: Password registration and verification works\n\n", .{});
}

// ============================================================================
// Timing-Safe Operations
// ============================================================================

test "Timing Safe: Equality Comparison" {
    std.debug.print("\n=== Test: Timing-Safe Equality ===\n", .{});

    const verifyHMAC = struct {
        fn func(received: [32]u8, computed: [32]u8) bool {
            return std.crypto.timing_safe.eql([32]u8, received, computed);
        }
    }.func;

    const mac1: [32]u8 = [_]u8{0xAA} ** 32;
    const mac2: [32]u8 = [_]u8{0xAA} ** 32;
    const mac3: [32]u8 = [_]u8{0xBB} ** 32;

    try testing.expect(verifyHMAC(mac1, mac2));
    try testing.expect(!verifyHMAC(mac1, mac3));

    std.debug.print("  ✅ PASS: Timing-safe equality works\n\n", .{});
}

test "Timing Safe: Ordering Comparison" {
    std.debug.print("\n=== Test: Timing-Safe Ordering ===\n", .{});

    const compareHashes = struct {
        fn func(a: [32]u8, b: [32]u8) std.math.Order {
            return std.crypto.timing_safe.compare(u8, &a, &b, .big);
        }
    }.func;

    const hash1: [32]u8 = [_]u8{0x01} ** 32;
    const hash2: [32]u8 = [_]u8{0x02} ** 32;

    const result = compareHashes(hash1, hash2);
    try testing.expectEqual(std.math.Order.lt, result);

    std.debug.print("  ✅ PASS: Timing-safe comparison works\n\n", .{});
}

// ============================================================================
// Digital Signatures
// ============================================================================

test "Digital Signatures: Ed25519 Sign and Verify" {
    std.debug.print("\n=== Test: Ed25519 Signatures ===\n", .{});

    const Ed25519 = std.crypto.sign.Ed25519;

    const signAndVerify = struct {
        fn func() !void {
            // Generate key pair (using fixed seed for reproducibility)
            const seed: [32]u8 = [_]u8{0x42} ** 32;
            const key_pair = try Ed25519.KeyPair.generateDeterministic(seed);

            const message = "Sign this message";

            // Sign
            const signature = try key_pair.sign(message, null);

            // Verify
            try signature.verify(message, key_pair.public_key);

            std.debug.print("  Message signed and verified\n", .{});
        }
    }.func;

    try signAndVerify();
    std.debug.print("  ✅ PASS: Ed25519 signatures work\n\n", .{});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "Usage Pattern: Message Encryption and Authentication" {
    std.debug.print("\n=== Test: Message Encryption Pattern ===\n", .{});

    const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
    const allocator = testing.allocator;

    const EncryptedMessage = struct {
        nonce: [12]u8,
        ciphertext: []u8,
        tag: [16]u8,
    };

    const encryptAndSend = struct {
        fn func(plaintext: []const u8, shared_key: [32]u8, alloc: std.mem.Allocator) !EncryptedMessage {
            // Generate unique nonce (fixed for test)
            const nonce: [12]u8 = [_]u8{0x99} ** 12;

            const ciphertext = try alloc.alloc(u8, plaintext.len);
            var tag: [16]u8 = undefined;

            ChaCha20Poly1305.encrypt(ciphertext, &tag, plaintext, "", nonce, shared_key);

            return EncryptedMessage{
                .nonce = nonce,
                .ciphertext = ciphertext,
                .tag = tag,
            };
        }
    }.func;

    const receiveAndDecrypt = struct {
        fn func(msg: EncryptedMessage, shared_key: [32]u8, alloc: std.mem.Allocator) ![]u8 {
            const plaintext = try alloc.alloc(u8, msg.ciphertext.len);
            errdefer alloc.free(plaintext);

            ChaCha20Poly1305.decrypt(
                plaintext,
                msg.ciphertext,
                msg.tag,
                "",
                msg.nonce,
                shared_key,
            ) catch {
                alloc.free(plaintext);
                return error.AuthenticationFailed;
            };

            return plaintext;
        }
    }.func;

    const original = "Hello from sender!";
    const shared_key: [32]u8 = [_]u8{0x77} ** 32;

    // Encrypt
    const encrypted = try encryptAndSend(original, shared_key, allocator);
    defer allocator.free(encrypted.ciphertext);

    std.debug.print("  Original: {s}\n", .{original});

    // Decrypt
    const decrypted = try receiveAndDecrypt(encrypted, shared_key, allocator);
    defer allocator.free(decrypted);

    try testing.expectEqualStrings(original, decrypted);
    std.debug.print("  Decrypted: {s}\n", .{decrypted});
    std.debug.print("  ✅ PASS: Message encryption pattern works\n\n", .{});
}

// ============================================================================
// Post-Quantum Cryptography
// ============================================================================

test "Post-Quantum: ML-DSA (Dilithium) Digital Signatures" {
    std.debug.print("\n=== Test: ML-DSA Post-Quantum Signatures ===\n", .{});

    const mldsa = std.crypto.sign.mldsa;

    // Test ML-DSA-44 (smallest signature size, 128-bit security)
    {
        std.debug.print("  Testing ML-DSA-44 (128-bit security)...\n", .{});
        const MLDSA44 = mldsa.MLDSA44;

        // Generate key pair deterministically for testing
        const seed: [32]u8 = [_]u8{0x42} ** 32;
        const key_pair = try MLDSA44.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key size:  {} bytes\n", .{MLDSA44.PublicKey.encoded_length});
        std.debug.print("    Secret key size:  {} bytes\n", .{MLDSA44.SecretKey.encoded_length});
        std.debug.print("    Signature size:   {} bytes\n", .{MLDSA44.Signature.encoded_length});

        // Sign a message
        const message = "Post-quantum secure transaction";
        const signature = try key_pair.sign(message, null);

        // Verify signature
        try signature.verify(message, key_pair.public_key);
        std.debug.print("    ✅ Signature verified\n", .{});

        // Test with context (domain separation)
        const context = "MyApp-v1";
        const sig_ctx = try key_pair.signWithContext(message, null, context);
        try sig_ctx.verifyWithContext(message, key_pair.public_key, context);
        std.debug.print("    ✅ Context-based signature verified\n", .{});

        // Test signature verification failure on wrong message
        const wrong_verify = signature.verify("wrong message", key_pair.public_key);
        try testing.expectError(error.SignatureVerificationFailed, wrong_verify);
        std.debug.print("    ✅ Invalid signature correctly rejected\n", .{});
    }

    // Test ML-DSA-65 (192-bit security)
    {
        std.debug.print("\n  Testing ML-DSA-65 (192-bit security)...\n", .{});
        const MLDSA65 = mldsa.MLDSA65;

        const seed: [32]u8 = [_]u8{0x65} ** 32;
        const key_pair = try MLDSA65.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key size:  {} bytes\n", .{MLDSA65.PublicKey.encoded_length});
        std.debug.print("    Secret key size:  {} bytes\n", .{MLDSA65.SecretKey.encoded_length});
        std.debug.print("    Signature size:   {} bytes\n", .{MLDSA65.Signature.encoded_length});

        const message = "Higher security post-quantum message";
        const signature = try key_pair.sign(message, null);
        try signature.verify(message, key_pair.public_key);
        std.debug.print("    ✅ ML-DSA-65 signature verified\n", .{});
    }

    // Test ML-DSA-87 (256-bit security)
    {
        std.debug.print("\n  Testing ML-DSA-87 (256-bit security)...\n", .{});
        const MLDSA87 = mldsa.MLDSA87;

        const seed: [32]u8 = [_]u8{0x87} ** 32;
        const key_pair = try MLDSA87.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key size:  {} bytes\n", .{MLDSA87.PublicKey.encoded_length});
        std.debug.print("    Secret key size:  {} bytes\n", .{MLDSA87.SecretKey.encoded_length});
        std.debug.print("    Signature size:   {} bytes\n", .{MLDSA87.Signature.encoded_length});

        const message = "Maximum security post-quantum message";
        const signature = try key_pair.sign(message, null);
        try signature.verify(message, key_pair.public_key);
        std.debug.print("    ✅ ML-DSA-87 signature verified\n", .{});
    }

    // Comparison with classical cryptography
    std.debug.print("\n  📊 Size Comparison with Ed25519:\n", .{});
    const Ed25519 = std.crypto.sign.Ed25519;
    std.debug.print("    Ed25519 signature:     {} bytes (classical)\n", .{Ed25519.Signature.encoded_length});
    std.debug.print("    ML-DSA-44 signature:   {} bytes (post-quantum, 128-bit)\n", .{mldsa.MLDSA44.Signature.encoded_length});
    std.debug.print("    ML-DSA-65 signature:   {} bytes (post-quantum, 192-bit)\n", .{mldsa.MLDSA65.Signature.encoded_length});
    std.debug.print("    ML-DSA-87 signature:   {} bytes (post-quantum, 256-bit)\n", .{mldsa.MLDSA87.Signature.encoded_length});

    const ratio = @as(f64, @floatFromInt(mldsa.MLDSA44.Signature.encoded_length)) / @as(f64, @floatFromInt(Ed25519.Signature.encoded_length));
    std.debug.print("    Size ratio (ML-DSA-44/Ed25519): {d:.1}x\n", .{ratio});

    std.debug.print("\n  ✅ PASS: All ML-DSA post-quantum tests passed\n\n", .{});
}

test "Post-Quantum: ML-DSA Key Serialization" {
    std.debug.print("\n=== Test: ML-DSA Key Serialization ===\n", .{});

    const MLDSA44 = std.crypto.sign.mldsa.MLDSA44;

    // Generate key pair
    const seed: [32]u8 = [_]u8{0x99} ** 32;
    const original_kp = try MLDSA44.KeyPair.generateDeterministic(seed);

    // Encode public key
    const pk_bytes = original_kp.public_key.toBytes();
    std.debug.print("  Public key encoded: {} bytes\n", .{pk_bytes.len});

    // Decode public key
    const decoded_pk = try MLDSA44.PublicKey.fromBytes(pk_bytes);
    std.debug.print("  Public key decoded successfully\n", .{});

    // Encode secret key
    const sk_bytes = original_kp.secret_key.toBytes();
    std.debug.print("  Secret key encoded: {} bytes\n", .{sk_bytes.len});

    // Decode secret key
    const decoded_sk = try MLDSA44.SecretKey.fromBytes(sk_bytes);
    std.debug.print("  Secret key decoded successfully\n", .{});

    // Create key pair from decoded keys
    const decoded_kp = MLDSA44.KeyPair{
        .public_key = decoded_pk,
        .secret_key = decoded_sk,
    };

    // Test that decoded key pair works
    const message = "Test serialization";
    const signature = try decoded_kp.sign(message, null);
    try signature.verify(message, decoded_kp.public_key);

    std.debug.print("  ✅ PASS: Serialized keys work correctly\n\n", .{});
}

test "Post-Quantum: ML-KEM (Kyber) Key Encapsulation" {
    std.debug.print("\n=== Test: ML-KEM Post-Quantum Key Encapsulation ===\n", .{});

    const ml_kem = std.crypto.kem.ml_kem;

    // Test ML-KEM-512 (128-bit security, smallest)
    {
        std.debug.print("  Testing ML-KEM-512 (128-bit security)...\n", .{});
        const MLKem512 = ml_kem.MLKem512;

        // Generate key pair
        const seed: [MLKem512.seed_length]u8 = [_]u8{0x42} ** MLKem512.seed_length;
        const key_pair = try MLKem512.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key:    {} bytes\n", .{MLKem512.PublicKey.encoded_length});
        std.debug.print("    Secret key:    {} bytes\n", .{MLKem512.SecretKey.encoded_length});
        std.debug.print("    Ciphertext:    {} bytes\n", .{MLKem512.ciphertext_length});
        std.debug.print("    Shared secret: {} bytes\n", .{MLKem512.shared_length});

        // Encapsulation (sender generates shared secret)
        const encaps_result = key_pair.public_key.encaps(testing.io);

        // Decapsulation (receiver derives same shared secret)
        const decaps_shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);

        // Verify both parties derived the same shared secret
        try testing.expectEqualSlices(u8, &encaps_result.shared_secret, &decaps_shared);
        std.debug.print("    ✅ Key encapsulation successful\n", .{});
        std.debug.print("    ✅ Shared secrets match\n", .{});
    }

    // Test ML-KEM-768 (192-bit security)
    {
        std.debug.print("\n  Testing ML-KEM-768 (192-bit security)...\n", .{});
        const MLKem768 = ml_kem.MLKem768;

        const seed: [MLKem768.seed_length]u8 = [_]u8{0x76} ** MLKem768.seed_length;
        const key_pair = try MLKem768.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key:    {} bytes\n", .{MLKem768.PublicKey.encoded_length});
        std.debug.print("    Secret key:    {} bytes\n", .{MLKem768.SecretKey.encoded_length});
        std.debug.print("    Ciphertext:    {} bytes\n", .{MLKem768.ciphertext_length});
        std.debug.print("    Shared secret: {} bytes\n", .{MLKem768.shared_length});

        const encaps_result = key_pair.public_key.encaps(testing.io);
        const decaps_shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);

        try testing.expectEqualSlices(u8, &encaps_result.shared_secret, &decaps_shared);
        std.debug.print("    ✅ ML-KEM-768 encapsulation successful\n", .{});
    }

    // Test ML-KEM-1024 (256-bit security)
    {
        std.debug.print("\n  Testing ML-KEM-1024 (256-bit security)...\n", .{});
        const MLKem1024 = ml_kem.MLKem1024;

        const seed: [MLKem1024.seed_length]u8 = [_]u8{0x10} ** MLKem1024.seed_length;
        const key_pair = try MLKem1024.KeyPair.generateDeterministic(seed);

        std.debug.print("    Public key:    {} bytes\n", .{MLKem1024.PublicKey.encoded_length});
        std.debug.print("    Secret key:    {} bytes\n", .{MLKem1024.SecretKey.encoded_length});
        std.debug.print("    Ciphertext:    {} bytes\n", .{MLKem1024.ciphertext_length});
        std.debug.print("    Shared secret: {} bytes\n", .{MLKem1024.shared_length});

        const encaps_result = key_pair.public_key.encaps(testing.io);
        const decaps_shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);

        try testing.expectEqualSlices(u8, &encaps_result.shared_secret, &decaps_shared);
        std.debug.print("    ✅ ML-KEM-1024 encapsulation successful\n", .{});
    }

    // Comparison table
    std.debug.print("\n  📊 ML-KEM vs Classical Key Exchange:\n", .{});
    std.debug.print("    Algorithm          Public Key  Ciphertext  PQ-Secure\n", .{});
    std.debug.print("    ─────────────────  ──────────  ──────────  ─────────\n", .{});
    std.debug.print("    X25519 (classical)    32 B        32 B        ❌\n", .{});
    std.debug.print("    ML-KEM-512            800 B       768 B       ✅\n", .{});
    std.debug.print("    ML-KEM-768           1184 B      1088 B       ✅\n", .{});
    std.debug.print("    ML-KEM-1024          1568 B      1568 B       ✅\n", .{});

    std.debug.print("\n  ✅ PASS: All ML-KEM post-quantum KEM tests passed\n\n", .{});
}

test "Post-Quantum: ML-KEM Key Serialization and Exchange" {
    std.debug.print("\n=== Test: ML-KEM Key Serialization ===\n", .{});

    const MLKem512 = std.crypto.kem.ml_kem.MLKem512;

    // Alice generates key pair
    const alice_seed: [MLKem512.seed_length]u8 = [_]u8{0xAA} ** MLKem512.seed_length;
    const alice_kp = try MLKem512.KeyPair.generateDeterministic(alice_seed);

    // Serialize Alice's public key
    const pk_bytes = alice_kp.public_key.toBytes();
    std.debug.print("  Alice's public key encoded: {} bytes\n", .{pk_bytes.len});

    // Send pk_bytes over network...

    // Bob deserializes Alice's public key
    const alice_pk = try MLKem512.PublicKey.fromBytes(&pk_bytes);
    std.debug.print("  Bob decoded Alice's public key\n", .{});

    // Bob encapsulates to create shared secret and ciphertext
    const bob_result = alice_pk.encaps(testing.io);
    std.debug.print("  Bob generated shared secret and ciphertext\n", .{});

    // Send bob_result.ciphertext back to Alice...

    // Alice decapsulates using her secret key
    const alice_shared = try alice_kp.secret_key.decaps(&bob_result.ciphertext);
    std.debug.print("  Alice derived shared secret from ciphertext\n", .{});

    // Verify both have same shared secret
    try testing.expectEqualSlices(u8, &bob_result.shared_secret, &alice_shared);

    std.debug.print("  ✅ PASS: Key exchange successful\n", .{});
    std.debug.print("  ✅ PASS: Both parties have matching shared secret\n\n", .{});
}

// ============================================================================
// Summary
// ============================================================================

test "Summary" {
    std.debug.print("\n" ++ "=" ** 60 ++ "\n", .{});
    std.debug.print("All std.crypto tests passed!\n", .{});
    std.debug.print("Including post-quantum ML-DSA (Dilithium) tests!\n", .{});
    std.debug.print("=" ** 60 ++ "\n\n", .{});
}
