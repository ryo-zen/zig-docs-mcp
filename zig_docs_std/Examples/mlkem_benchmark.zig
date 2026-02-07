// ML-KEM (Kyber) Parameter Set Benchmark
// Compares performance and characteristics of ML-KEM-512, ML-KEM-768, and ML-KEM-1024
//
// Run with: zig run mlkem_benchmark.zig
//
// This benchmark demonstrates the tradeoffs between the three NIST-standardized
// ML-KEM parameter sets as described in FIPS 203.

const std = @import("std");
const ml_kem = std.crypto.kem.ml_kem;
const time = std.time;

const BenchmarkResult = struct {
    name: []const u8,
    security_bits: u32,
    public_key_bytes: usize,
    secret_key_bytes: usize,
    ciphertext_bytes: usize,
    shared_secret_bytes: usize,
    keygen_ns: u64,
    encaps_ns: u64,
    decaps_ns: u64,
    total_exchange_ns: u64,
};

fn benchmarkMLKem512(iterations: usize) !BenchmarkResult {
    const MLKem512 = ml_kem.MLKem512;

    var keygen_total: u64 = 0;
    var encaps_total: u64 = 0;
    var decaps_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // Benchmark key generation
        const seed: [MLKem512.seed_length]u8 = [_]u8{0x42 + @as(u8, @intCast(i % 256))} ** MLKem512.seed_length;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLKem512.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        // Benchmark encapsulation
        const encaps_seed: [MLKem512.encaps_seed_length]u8 = [_]u8{0x11 + @as(u8, @intCast(i % 256))} ** MLKem512.encaps_seed_length;
        const encaps_start = try time.Instant.now();
        const encaps_result = key_pair.public_key.encapsDeterministic(&encaps_seed);
        const encaps_end = try time.Instant.now();
        encaps_total += encaps_end.since(encaps_start);

        // Benchmark decapsulation
        const decaps_start = try time.Instant.now();
        const shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);
        const decaps_end = try time.Instant.now();
        decaps_total += decaps_end.since(decaps_start);

        // Verify correctness
        if (!std.mem.eql(u8, &encaps_result.shared_secret, &shared)) {
            return error.SharedSecretMismatch;
        }
    }

    const keygen_avg = keygen_total / iterations;
    const encaps_avg = encaps_total / iterations;
    const decaps_avg = decaps_total / iterations;

    return BenchmarkResult{
        .name = "ML-KEM-512",
        .security_bits = 128,
        .public_key_bytes = MLKem512.PublicKey.encoded_length,
        .secret_key_bytes = MLKem512.SecretKey.encoded_length,
        .ciphertext_bytes = MLKem512.ciphertext_length,
        .shared_secret_bytes = MLKem512.shared_length,
        .keygen_ns = keygen_avg,
        .encaps_ns = encaps_avg,
        .decaps_ns = decaps_avg,
        .total_exchange_ns = keygen_avg + encaps_avg + decaps_avg,
    };
}

fn benchmarkMLKem768(iterations: usize) !BenchmarkResult {
    const MLKem768 = ml_kem.MLKem768;

    var keygen_total: u64 = 0;
    var encaps_total: u64 = 0;
    var decaps_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const seed: [MLKem768.seed_length]u8 = [_]u8{0x76 + @as(u8, @intCast(i % 256))} ** MLKem768.seed_length;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLKem768.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        const encaps_seed: [MLKem768.encaps_seed_length]u8 = [_]u8{0x22 + @as(u8, @intCast(i % 256))} ** MLKem768.encaps_seed_length;
        const encaps_start = try time.Instant.now();
        const encaps_result = key_pair.public_key.encapsDeterministic(&encaps_seed);
        const encaps_end = try time.Instant.now();
        encaps_total += encaps_end.since(encaps_start);

        const decaps_start = try time.Instant.now();
        const shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);
        const decaps_end = try time.Instant.now();
        decaps_total += decaps_end.since(decaps_start);

        if (!std.mem.eql(u8, &encaps_result.shared_secret, &shared)) {
            return error.SharedSecretMismatch;
        }
    }

    const keygen_avg = keygen_total / iterations;
    const encaps_avg = encaps_total / iterations;
    const decaps_avg = decaps_total / iterations;

    return BenchmarkResult{
        .name = "ML-KEM-768",
        .security_bits = 192,
        .public_key_bytes = MLKem768.PublicKey.encoded_length,
        .secret_key_bytes = MLKem768.SecretKey.encoded_length,
        .ciphertext_bytes = MLKem768.ciphertext_length,
        .shared_secret_bytes = MLKem768.shared_length,
        .keygen_ns = keygen_avg,
        .encaps_ns = encaps_avg,
        .decaps_ns = decaps_avg,
        .total_exchange_ns = keygen_avg + encaps_avg + decaps_avg,
    };
}

fn benchmarkMLKem1024(iterations: usize) !BenchmarkResult {
    const MLKem1024 = ml_kem.MLKem1024;

    var keygen_total: u64 = 0;
    var encaps_total: u64 = 0;
    var decaps_total: u64 = 0;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const seed: [MLKem1024.seed_length]u8 = [_]u8{0x10 + @as(u8, @intCast(i % 256))} ** MLKem1024.seed_length;

        const keygen_start = try time.Instant.now();
        const key_pair = try MLKem1024.KeyPair.generateDeterministic(seed);
        const keygen_end = try time.Instant.now();
        keygen_total += keygen_end.since(keygen_start);

        const encaps_seed: [MLKem1024.encaps_seed_length]u8 = [_]u8{0x33 + @as(u8, @intCast(i % 256))} ** MLKem1024.encaps_seed_length;
        const encaps_start = try time.Instant.now();
        const encaps_result = key_pair.public_key.encapsDeterministic(&encaps_seed);
        const encaps_end = try time.Instant.now();
        encaps_total += encaps_end.since(encaps_start);

        const decaps_start = try time.Instant.now();
        const shared = try key_pair.secret_key.decaps(&encaps_result.ciphertext);
        const decaps_end = try time.Instant.now();
        decaps_total += decaps_end.since(decaps_start);

        if (!std.mem.eql(u8, &encaps_result.shared_secret, &shared)) {
            return error.SharedSecretMismatch;
        }
    }

    const keygen_avg = keygen_total / iterations;
    const encaps_avg = encaps_total / iterations;
    const decaps_avg = decaps_total / iterations;

    return BenchmarkResult{
        .name = "ML-KEM-1024",
        .security_bits = 256,
        .public_key_bytes = MLKem1024.PublicKey.encoded_length,
        .secret_key_bytes = MLKem1024.SecretKey.encoded_length,
        .ciphertext_bytes = MLKem1024.ciphertext_length,
        .shared_secret_bytes = MLKem1024.shared_length,
        .keygen_ns = keygen_avg,
        .encaps_ns = encaps_avg,
        .decaps_ns = decaps_avg,
        .total_exchange_ns = keygen_avg + encaps_avg + decaps_avg,
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
    std.debug.print("ML-KEM PARAMETER SET COMPARISON (FIPS 203)\n", .{});
    std.debug.print("=" ** 90 ++ "\n\n", .{});

    // Size comparison table
    std.debug.print("📏 Key and Ciphertext Sizes:\n\n", .{});
    std.debug.print("Parameter Set    Security  Public Key  Secret Key  Ciphertext  Shared Secret\n", .{});
    std.debug.print("───────────────  ────────  ──────────  ──────────  ──────────  ─────────────\n", .{});

    for (results) |r| {
        std.debug.print("{s:<15}  {d:>3}-bit     {d:>6} B     {d:>6} B     {d:>6} B        {d:>4} B\n", .{
            r.name,
            r.security_bits,
            r.public_key_bytes,
            r.secret_key_bytes,
            r.ciphertext_bytes,
            r.shared_secret_bytes,
        });
    }

    // Performance comparison
    std.debug.print("\n⚡ Performance Benchmark:\n\n", .{});
    std.debug.print("Parameter Set    Key Generation  Encapsulation   Decapsulation   Total Exchange\n", .{});
    std.debug.print("───────────────  ──────────────  ──────────────  ──────────────  ──────────────\n", .{});

    for (results) |r| {
        std.debug.print("{s:<15}  ", .{r.name});
        formatNanoseconds(r.keygen_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.encaps_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.decaps_ns);
        std.debug.print("       ", .{});
        formatNanoseconds(r.total_exchange_ns);
        std.debug.print("\n", .{});
    }

    // Relative comparison (baseline: ML-KEM-512)
    std.debug.print("\n📊 Relative Performance (vs ML-KEM-512 baseline):\n\n", .{});
    const baseline = results[0];

    std.debug.print("Parameter Set    Size Overhead   Speed Overhead\n", .{});
    std.debug.print("───────────────  ─────────────   ──────────────\n", .{});

    for (results) |r| {
        const size_ratio = @as(f64, @floatFromInt(r.public_key_bytes)) / @as(f64, @floatFromInt(baseline.public_key_bytes));
        const speed_ratio = @as(f64, @floatFromInt(r.total_exchange_ns)) / @as(f64, @floatFromInt(baseline.total_exchange_ns));

        std.debug.print("{s:<15}     {d:>4.2}x           {d:>4.2}x\n", .{
            r.name,
            size_ratio,
            speed_ratio,
        });
    }

    // NIST recommendations
    std.debug.print("\n💡 NIST FIPS 203 Recommendations:\n\n", .{});
    std.debug.print("  • ML-KEM-512  → Smallest/Fastest (128-bit PQ security = NIST Category 1)\n", .{});
    std.debug.print("  • ML-KEM-768  → RECOMMENDED DEFAULT (192-bit PQ security = NIST Category 3)\n", .{});
    std.debug.print("  • ML-KEM-1024 → Maximum Security (256-bit PQ security = NIST Category 5)\n", .{});

    std.debug.print("\n📝 Key Takeaways:\n\n", .{});
    std.debug.print("  1. ML-KEM-768 is the recommended default - good security/performance balance\n", .{});
    std.debug.print("  2. ML-KEM-512 is acceptable when size/speed are critical (still 128-bit PQ secure)\n", .{});
    std.debug.print("  3. ML-KEM-1024 for maximum long-term security (large margin, future-proof)\n", .{});
    std.debug.print("  4. All variants produce the same 32-byte shared secret\n", .{});
    std.debug.print("  5. Performance scales roughly linearly with security level\n", .{});

    std.debug.print("\n" ++ "=" ** 90 ++ "\n\n", .{});
}

pub fn main() !void {
    const iterations: usize = 1000;

    std.debug.print("\n🔬 Benchmarking ML-KEM Parameter Sets ({} iterations each)...\n\n", .{iterations});

    std.debug.print("Running ML-KEM-512 benchmark...\n", .{});
    const result_512 = try benchmarkMLKem512(iterations);

    std.debug.print("Running ML-KEM-768 benchmark...\n", .{});
    const result_768 = try benchmarkMLKem768(iterations);

    std.debug.print("Running ML-KEM-1024 benchmark...\n", .{});
    const result_1024 = try benchmarkMLKem1024(iterations);

    const results = [_]BenchmarkResult{ result_512, result_768, result_1024 };
    printResults(&results);

    std.debug.print("✅ Benchmark completed successfully!\n\n", .{});
}
