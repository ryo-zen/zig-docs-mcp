// ML-DSA (Dilithium) Parameter Set Benchmark
// Compares performance and characteristics of ML-DSA-44, ML-DSA-65, and ML-DSA-87
//
// Run with: zig run mldsa_benchmark.zig -O ReleaseFast
//
// This benchmark demonstrates the tradeoffs between the three NIST-standardized
// ML-DSA parameter sets as described in FIPS 204.

const std = @import("std");
const mldsa = std.crypto.sign.mldsa;
const time = std.time;

const BenchmarkResult = struct {
    name: []const u8,
    security_bits: u32,
    public_key_bytes: usize,
    secret_key_bytes: usize,
    signature_bytes: usize,
    keygen_ns: u64,
    sign_ns: u64,
    verify_ns: u64,
    total_sign_verify_ns: u64,
};

fn benchmarkMLDSA44(iterations: usize) !BenchmarkResult {
    const MLDSA44 = mldsa.MLDSA44;

    var keygen_total: u64 = 0;
    var sign_total: u64 = 0;
    var verify_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // Benchmark key generation
        const seed: [32]u8 = [_]u8{0x44 + @as(u8, @intCast(i % 256))} ** 32;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLDSA44.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        // Prepare message to sign
        const message = "This is a test message for benchmarking ML-DSA signatures";

        // Benchmark signing
        const sign_start = try time.Instant.now();
        const signature = try key_pair.sign(message, null);
        const sign_end = try time.Instant.now();
        sign_total += sign_end.since(sign_start);

        // Benchmark verification
        const verify_start = try time.Instant.now();
        try signature.verify(message, key_pair.public_key);
        const verify_end = try time.Instant.now();
        verify_total += verify_end.since(verify_start);
    }

    const keygen_avg = keygen_total / iterations;
    const sign_avg = sign_total / iterations;
    const verify_avg = verify_total / iterations;

    return BenchmarkResult{
        .name = "ML-DSA-44",
        .security_bits = 128,
        .public_key_bytes = MLDSA44.PublicKey.encoded_length,
        .secret_key_bytes = MLDSA44.SecretKey.encoded_length,
        .signature_bytes = MLDSA44.Signature.encoded_length,
        .keygen_ns = keygen_avg,
        .sign_ns = sign_avg,
        .verify_ns = verify_avg,
        .total_sign_verify_ns = sign_avg + verify_avg,
    };
}

fn benchmarkMLDSA65(iterations: usize) !BenchmarkResult {
    const MLDSA65 = mldsa.MLDSA65;

    var keygen_total: u64 = 0;
    var sign_total: u64 = 0;
    var verify_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const seed: [32]u8 = [_]u8{0x65 + @as(u8, @intCast(i % 256))} ** 32;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLDSA65.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        const message = "This is a test message for benchmarking ML-DSA signatures";

        const sign_start = try time.Instant.now();
        const signature = try key_pair.sign(message, null);
        const sign_end = try time.Instant.now();
        sign_total += sign_end.since(sign_start);

        const verify_start = try time.Instant.now();
        try signature.verify(message, key_pair.public_key);
        const verify_end = try time.Instant.now();
        verify_total += verify_end.since(verify_start);
    }

    const keygen_avg = keygen_total / iterations;
    const sign_avg = sign_total / iterations;
    const verify_avg = verify_total / iterations;

    return BenchmarkResult{
        .name = "ML-DSA-65",
        .security_bits = 192,
        .public_key_bytes = MLDSA65.PublicKey.encoded_length,
        .secret_key_bytes = MLDSA65.SecretKey.encoded_length,
        .signature_bytes = MLDSA65.Signature.encoded_length,
        .keygen_ns = keygen_avg,
        .sign_ns = sign_avg,
        .verify_ns = verify_avg,
        .total_sign_verify_ns = sign_avg + verify_avg,
    };
}

fn benchmarkMLDSA87(iterations: usize) !BenchmarkResult {
    const MLDSA87 = mldsa.MLDSA87;

    var keygen_total: u64 = 0;
    var sign_total: u64 = 0;
    var verify_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const seed: [32]u8 = [_]u8{0x87 + @as(u8, @intCast(i % 256))} ** 32;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLDSA87.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        const message = "This is a test message for benchmarking ML-DSA signatures";

        const sign_start = try time.Instant.now();
        const signature = try key_pair.sign(message, null);
        const sign_end = try time.Instant.now();
        sign_total += sign_end.since(sign_start);

        const verify_start = try time.Instant.now();
        try signature.verify(message, key_pair.public_key);
        const verify_end = try time.Instant.now();
        verify_total += verify_end.since(verify_start);
    }

    const keygen_avg = keygen_total / iterations;
    const sign_avg = sign_total / iterations;
    const verify_avg = verify_total / iterations;

    return BenchmarkResult{
        .name = "ML-DSA-87",
        .security_bits = 256,
        .public_key_bytes = MLDSA87.PublicKey.encoded_length,
        .secret_key_bytes = MLDSA87.SecretKey.encoded_length,
        .signature_bytes = MLDSA87.Signature.encoded_length,
        .keygen_ns = keygen_avg,
        .sign_ns = sign_avg,
        .verify_ns = verify_avg,
        .total_sign_verify_ns = sign_avg + verify_avg,
    };
}

fn formatNanoseconds(ns: u64) void {
    if (ns < 1000) {
        std.debug.print("{d:>7} ns", .{ns});
    } else if (ns < 1_000_000) {
        const us = @as(f64, @floatFromInt(ns)) / 1000.0;
        std.debug.print("{d:>7.2} µs", .{us});
    } else if (ns < 1_000_000_000) {
        const ms = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
        std.debug.print("{d:>7.2} ms", .{ms});
    } else {
        const s = @as(f64, @floatFromInt(ns)) / 1_000_000_000.0;
        std.debug.print("{d:>7.2} s", .{s});
    }
}

fn printResults(results: []const BenchmarkResult) void {
    std.debug.print("\n" ++ "=" ** 90 ++ "\n", .{});
    std.debug.print("ML-DSA (DILITHIUM) PARAMETER SET COMPARISON (FIPS 204)\n", .{});
    std.debug.print("=" ** 90 ++ "\n\n", .{});

    // Size comparison table
    std.debug.print("📏 Key and Signature Sizes:\n\n", .{});
    std.debug.print("Parameter Set    Security  Public Key  Secret Key  Signature\n", .{});
    std.debug.print("───────────────  ────────  ──────────  ──────────  ─────────\n", .{});

    for (results) |r| {
        std.debug.print("{s:<15}  {d:>3}-bit     {d:>6} B     {d:>6} B    {d:>6} B\n", .{
            r.name,
            r.security_bits,
            r.public_key_bytes,
            r.secret_key_bytes,
            r.signature_bytes,
        });
    }

    // Performance comparison
    std.debug.print("\n⚡ Performance Benchmark:\n\n", .{});
    std.debug.print("Parameter Set    Key Generation  Sign Message    Verify Sig      Sign+Verify\n", .{});
    std.debug.print("───────────────  ──────────────  ──────────────  ──────────────  ──────────────\n", .{});

    for (results) |r| {
        std.debug.print("{s:<15}  ", .{r.name});
        formatNanoseconds(r.keygen_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.sign_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.verify_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.total_sign_verify_ns);
        std.debug.print("\n", .{});
    }

    // Relative comparison (baseline: ML-DSA-44)
    std.debug.print("\n📊 Relative Performance (vs ML-DSA-44 baseline):\n\n", .{});
    const baseline = results[0];

    std.debug.print("Parameter Set    Signature Size  Speed Overhead\n", .{});
    std.debug.print("───────────────  ──────────────  ──────────────\n", .{});

    for (results) |r| {
        const size_ratio = @as(f64, @floatFromInt(r.signature_bytes)) / @as(f64, @floatFromInt(baseline.signature_bytes));
        const speed_ratio = @as(f64, @floatFromInt(r.total_sign_verify_ns)) / @as(f64, @floatFromInt(baseline.total_sign_verify_ns));

        std.debug.print("{s:<15}     {d:>4.2}x           {d:>4.2}x\n", .{
            r.name,
            size_ratio,
            speed_ratio,
        });
    }

    // Comparison with Ed25519
    std.debug.print("\n📊 Comparison with Classical Ed25519:\n\n", .{});
    const Ed25519 = std.crypto.sign.Ed25519;
    std.debug.print("Algorithm        Public Key  Secret Key  Signature   Quantum Safe\n", .{});
    std.debug.print("───────────────  ──────────  ──────────  ─────────   ────────────\n", .{});
    std.debug.print("Ed25519 (RSA)       32 B        64 B        64 B          ❌\n", .{});
    for (results) |r| {
        std.debug.print("{s:<15}   {d:>6} B     {d:>6} B    {d:>6} B         ✅\n", .{
            r.name,
            r.public_key_bytes,
            r.secret_key_bytes,
            r.signature_bytes,
        });
    }

    // Calculate size overhead
    std.debug.print("\n  Signature Size Overhead vs Ed25519:\n", .{});
    for (results) |r| {
        const ratio = @as(f64, @floatFromInt(r.signature_bytes)) / @as(f64, @floatFromInt(Ed25519.Signature.encoded_length));
        std.debug.print("  • {s}: {d:.1}x larger ({} bytes vs {} bytes)\n", .{
            r.name,
            ratio,
            r.signature_bytes,
            Ed25519.Signature.encoded_length,
        });
    }

    // NIST recommendations
    std.debug.print("\n💡 NIST FIPS 204 Recommendations:\n\n", .{});
    std.debug.print("  • ML-DSA-44  → Smallest/Fastest (128-bit PQ security = NIST Category 2)\n", .{});
    std.debug.print("  • ML-DSA-65  → Balanced Option (192-bit PQ security = NIST Category 3)\n", .{});
    std.debug.print("  • ML-DSA-87  → Maximum Security (256-bit PQ security = NIST Category 5)\n", .{});

    std.debug.print("\n📝 Key Takeaways:\n\n", .{});
    std.debug.print("  1. ML-DSA signatures are 38-72x larger than Ed25519 but quantum-resistant\n", .{});
    std.debug.print("  2. ML-DSA-44 provides good performance with 2.4 kB signatures\n", .{});
    std.debug.print("  3. ML-DSA-65 adds only ~37% overhead for 50% more security bits\n", .{});
    std.debug.print("  4. All variants are fast enough for real-world use (microseconds)\n", .{});
    std.debug.print("  5. Choose based on long-term security needs and bandwidth constraints\n", .{});

    std.debug.print("\n" ++ "=" ** 90 ++ "\n\n", .{});
}

pub fn main() !void {
    const iterations: usize = 1000;

    std.debug.print("\n🔬 Benchmarking ML-DSA Parameter Sets ({} iterations each)...\n\n", .{iterations});

    std.debug.print("Running ML-DSA-44 benchmark...\n", .{});
    const result_44 = try benchmarkMLDSA44(iterations);

    std.debug.print("Running ML-DSA-65 benchmark...\n", .{});
    const result_65 = try benchmarkMLDSA65(iterations);

    std.debug.print("Running ML-DSA-87 benchmark...\n", .{});
    const result_87 = try benchmarkMLDSA87(iterations);

    const results = [_]BenchmarkResult{ result_44, result_65, result_87 };
    printResults(&results);

    std.debug.print("✅ Benchmark completed successfully!\n\n", .{});
}
