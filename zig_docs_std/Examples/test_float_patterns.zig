const std = @import("std");

// Float literal examples
test "float literals" {
    const floating_point = 123.0E+77;
    const another_float = 123.0;
    const yet_another = 123.0e+77;

    const hex_floating_point = 0x103.70p-5;
    const another_hex_float = 0x103.70;
    const yet_another_hex_float = 0x103.70P-5;

    const lightspeed = 299_792_458.000_000;
    const nanosecond = 0.000_000_001;
    const more_hex = 0x1234_5678.9ABC_CDEFp-10;

    _ = floating_point;
    _ = another_float;
    _ = yet_another;
    _ = hex_floating_point;
    _ = another_hex_float;
    _ = yet_another_hex_float;
    _ = lightspeed;
    _ = nanosecond;
    _ = more_hex;
}

// Special values
test "special values" {
    const inf = std.math.inf(f32);
    const negative_inf = -std.math.inf(f64);
    const nan = std.math.nan(f128);

    try std.testing.expect(std.math.isInf(inf));
    try std.testing.expect(std.math.isInf(negative_inf));
    try std.testing.expect(std.math.isNan(nan));
}

// Epsilon comparison (avoiding == for floats)
test "epsilon comparison" {
    const a: f32 = 0.1 + 0.2;
    const b: f32 = 0.3;

    // Direct comparison may fail
    // if (a == b) - unreliable!

    // Use epsilon comparison
    try std.testing.expect(std.math.approxEqAbs(f32, a, b, 0.0001));
}

// Precision loss demonstration
test "precision loss with f32" {
    const x: f32 = 16777216.0; // 2^24
    const y: f32 = x + 1.0;

    // The +1.0 is lost due to precision limits
    try std.testing.expect(x == y);

    // With f64, it works
    const x64: f64 = 16777216.0;
    const y64: f64 = x64 + 1.0;
    try std.testing.expect(y64 > x64);
}

// NaN propagation
test "NaN propagation" {
    const nan = std.math.nan(f32);
    const result = nan + 10.0;

    // Any operation with NaN produces NaN
    try std.testing.expect(std.math.isNan(result));
}

// Currency handling (correct way with integers)
test "currency with integers" {
    const Money = struct {
        cents: i64,

        pub fn add(self: @This(), other: @This()) @This() {
            return .{ .cents = self.cents + other.cents };
        }

        pub fn toDollars(self: @This()) f64 {
            return @as(f64, @floatFromInt(self.cents)) / 100.0;
        }
    };

    var balance = Money{ .cents = 0 };
    balance = balance.add(Money{ .cents = 10 }); // $0.10
    balance = balance.add(Money{ .cents = 10 }); // $0.10
    balance = balance.add(Money{ .cents = 10 }); // $0.10

    try std.testing.expect(balance.cents == 30);
    try std.testing.expect(balance.toDollars() == 0.30);
}

// Signed zero
test "signed zero" {
    const pos_zero: f32 = 0.0;
    const neg_zero: f32 = -0.0;

    // They compare equal
    try std.testing.expect(pos_zero == neg_zero);

    // But have different signs
    try std.testing.expect(!std.math.signbit(pos_zero));
    try std.testing.expect(std.math.signbit(neg_zero));

    // Different behavior in division
    const pos_inf = 1.0 / pos_zero;
    const neg_inf = 1.0 / neg_zero;
    try std.testing.expect(std.math.isInf(pos_inf));
    try std.testing.expect(std.math.isInf(neg_inf));
    try std.testing.expect(pos_inf > 0);
    try std.testing.expect(neg_inf < 0);
}

// Overflow to infinity
test "overflow to infinity" {
    const huge: f32 = 1.0e38;
    const result = huge * huge;

    try std.testing.expect(std.math.isInf(result));
}

// Rounding operations
test "rounding operations" {
    const x: f32 = 3.7;

    try std.testing.expect(std.math.round(x) == 4.0);
    try std.testing.expect(std.math.floor(x) == 3.0);
    try std.testing.expect(std.math.ceil(x) == 4.0);
    try std.testing.expect(std.math.trunc(x) == 3.0);

    const negative: f32 = -3.7;
    try std.testing.expect(std.math.round(negative) == -4.0);
    try std.testing.expect(std.math.floor(negative) == -4.0);
    try std.testing.expect(std.math.ceil(negative) == -3.0);
    try std.testing.expect(std.math.trunc(negative) == -3.0);
}

// Float comparison functions
test "float comparison functions" {
    const a: f64 = 0.1 + 0.2;
    const b: f64 = 0.3;

    // Absolute difference comparison
    try std.testing.expect(std.math.approxEqAbs(f64, a, b, 0.0001));

    // Relative difference comparison
    try std.testing.expect(std.math.approxEqRel(f64, a, b, 0.0001));

    // Min/Max (use @min/@max builtins)
    try std.testing.expect(@min(a, b) <= a);
    try std.testing.expect(@max(a, b) >= b);
}

// Mathematical functions
test "math functions" {
    const x: f64 = 2.0;

    // Power and roots
    try std.testing.expect(std.math.pow(f64, x, 3.0) == 8.0);
    try std.testing.expect(std.math.sqrt(x) > 1.4);
    try std.testing.expect(std.math.cbrt(x) > 1.2);

    // Exponential and logarithms
    const e_to_x = std.math.exp(x);
    try std.testing.expect(e_to_x > 7.0);

    const ln_x = std.math.log(f64, std.math.e, x);
    try std.testing.expect(std.math.approxEqAbs(f64, ln_x, 0.693, 0.001));

    // Trigonometry
    const sine = std.math.sin(x);
    const cosine = std.math.cos(x);
    _ = sine;
    _ = cosine;

    // Absolute value
    try std.testing.expect(@abs(-3.14) == 3.14);
}

// Classification functions
test "float classification" {
    try std.testing.expect(std.math.isNan(std.math.nan(f32)));
    try std.testing.expect(std.math.isInf(std.math.inf(f64)));

    const finite_val: f32 = 42.0;
    try std.testing.expect(std.math.isFinite(finite_val));

    const normal_val: f32 = 1.0;
    try std.testing.expect(std.math.isNormal(normal_val));

    // Sign operations
    const neg_zero: f32 = -0.0;
    try std.testing.expect(std.math.signbit(neg_zero));

    const magnitude: f32 = 5.0;
    const sign: f32 = -1.0;
    const copied_sign = std.math.copysign(magnitude, sign);
    try std.testing.expect(copied_sign == -5.0);
}

// Physics vector pattern
test "physics vector" {
    const Vec2 = struct {
        x: f32,
        y: f32,

        pub fn length(self: @This()) f32 {
            return std.math.sqrt(self.x * self.x + self.y * self.y);
        }

        pub fn normalize(self: @This()) @This() {
            const len = self.length();
            if (len < 0.0001) return .{ .x = 0, .y = 0 };
            return .{ .x = self.x / len, .y = self.y / len };
        }
    };

    const v = Vec2{ .x = 3.0, .y = 4.0 };
    try std.testing.expect(std.math.approxEqAbs(f32, v.length(), 5.0, 0.0001));

    const normalized = v.normalize();
    try std.testing.expect(std.math.approxEqAbs(f32, normalized.length(), 1.0, 0.0001));
}

// GPS coordinates pattern
test "GPS distance calculation" {
    const Coordinate = struct {
        latitude: f64,
        longitude: f64,

        pub fn distanceTo(self: @This(), other: @This()) f64 {
            const earth_radius_km = 6371.0;
            const lat1 = self.latitude * std.math.pi / 180.0;
            const lat2 = other.latitude * std.math.pi / 180.0;
            const delta_lat = (other.latitude - self.latitude) * std.math.pi / 180.0;
            const delta_lon = (other.longitude - self.longitude) * std.math.pi / 180.0;

            const a = std.math.sin(delta_lat / 2.0) * std.math.sin(delta_lat / 2.0) +
                std.math.cos(lat1) * std.math.cos(lat2) *
                std.math.sin(delta_lon / 2.0) * std.math.sin(delta_lon / 2.0);
            const c = 2.0 * std.math.atan2(std.math.sqrt(a), std.math.sqrt(1.0 - a));

            return earth_radius_km * c;
        }
    };

    const new_york = Coordinate{ .latitude = 40.7128, .longitude = -74.0060 };
    const london = Coordinate{ .latitude = 51.5074, .longitude = -0.1278 };

    const distance = new_york.distanceTo(london);
    // Should be approximately 5570 km
    try std.testing.expect(distance > 5500.0 and distance < 5600.0);
}

// Currency pattern (correct implementation)
test "currency handling pattern" {
    const Money = struct {
        cents: i64,

        pub fn fromDollars(dollars: f64) @This() {
            return .{ .cents = @intFromFloat(dollars * 100.0) };
        }

        pub fn toDollars(self: @This()) f64 {
            return @as(f64, @floatFromInt(self.cents)) / 100.0;
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return .{ .cents = self.cents + other.cents };
        }
    };

    var balance = Money{ .cents = 0 };
    balance = balance.add(Money{ .cents = 10 });
    balance = balance.add(Money{ .cents = 10 });
    balance = balance.add(Money{ .cents = 10 });

    try std.testing.expect(balance.cents == 30);
    try std.testing.expect(balance.toDollars() == 0.30);
}

// Numerical integration pattern
test "numerical integration" {
    const Integration = struct {
        fn integrate(comptime f: fn (f64) f64, a: f64, b: f64, n: usize) f64 {
            const h = (b - a) / @as(f64, @floatFromInt(n));
            var sum: f64 = f(a) + f(b);

            var i: usize = 1;
            while (i < n) : (i += 2) {
                sum += 4.0 * f(a + @as(f64, @floatFromInt(i)) * h);
            }

            i = 2;
            while (i < n) : (i += 2) {
                sum += 2.0 * f(a + @as(f64, @floatFromInt(i)) * h);
            }

            return sum * h / 3.0;
        }

        fn square(x: f64) f64 {
            return x * x;
        }
    };

    // Integrate x^2 from 0 to 1 (should be 1/3)
    const result = Integration.integrate(Integration.square, 0.0, 1.0, 1000);
    try std.testing.expect(std.math.approxEqAbs(f64, result, 1.0 / 3.0, 0.0001));
}

// Fused multiply-add
test "fused multiply-add" {
    const a: f64 = 2.0;
    const b: f64 = 3.0;
    const c: f64 = 4.0;

    // Use @mulAdd builtin for fused multiply-add
    const result_fma = @mulAdd(f64, a, b, c); // a*b + c
    const result_normal = a * b + c;

    // Both should be close to 10.0
    try std.testing.expect(std.math.approxEqAbs(f64, result_fma, 10.0, 0.0001));
    try std.testing.expect(std.math.approxEqAbs(f64, result_normal, 10.0, 0.0001));
}
