# std.math.big.int.Const.toFloat

Convert self to `Float`.

## Parameters

    self: Const

    Float: type

    round: Round

## Source Code

```
pub fn toFloat(self: Const, comptime Float: type, round: Round) struct { Float, Exactness } {
    if (Float == comptime_float) return self.toFloat(f128, round);
    const normalized_abs: Const = .{
        .limbs = self.limbs[0..llnormalize(self.limbs)],
        .positive = true,
    };
    if (normalized_abs.eqlZero()) return .{ if (self.positive) 0.0 else -0.0, .exact };

    const Repr = std.math.FloatRepr(Float);
    var mantissa_limbs: [calcNonZeroTwosCompLimbCount(1 + @bitSizeOf(Repr.Mantissa))]Limb = undefined;
    var mantissa: Mutable = .{
        .limbs = &mantissa_limbs,
        .positive = undefined,
        .len = undefined,
    };
    var exponent = normalized_abs.bitCountAbs() - 1;
    const exactness: Exactness = exactness: {
        if (exponent <= @bitSizeOf(Repr.Normalized.Fraction)) {
            mantissa.shiftLeft(normalized_abs, @intCast(@bitSizeOf(Repr.Normalized.Fraction) - exponent));
            break :exactness .exact;
        }
        const shift: usize = @intCast(exponent - @bitSizeOf(Repr.Normalized.Fraction));
        mantissa.shiftRight(normalized_abs, shift);
        const final_limb_index = (shift - 1) / limb_bits;
        const round_bits = normalized_abs.limbs[final_limb_index] << @truncate(-%shift) |
            @intFromBool(!std.mem.allEqual(Limb, normalized_abs.limbs[0..final_limb_index], 0));
        if (round_bits == 0) break :exactness .exact;
        round: switch (round) {
            .nearest_even => {
                const half: Limb = 1 << (limb_bits - 1);
                if (round_bits >= half) mantissa.addScalar(mantissa.toConst(), 1);
                if (round_bits == half) mantissa.limbs[0] &= ~@as(Limb, 1);
            },
            .away => mantissa.addScalar(mantissa.toConst(), 1),
            .trunc => {},
            .floor => if (!self.positive) continue :round .away,
            .ceil => if (self.positive) continue :round .away,
        }
        break :exactness .inexact;
    };
    const normalized_res: Repr.Normalized = .{
        .fraction = @truncate(mantissa.toInt(Repr.Mantissa) catch |err| switch (err) {
            error.NegativeIntoUnsigned => unreachable,
            error.TargetTooSmall => fraction: {
                assert(mantissa.toConst().orderAgainstScalar(1 << @bitSizeOf(Repr.Mantissa)).compare(.eq));
                exponent += 1;
                break :fraction 1 << (@bitSizeOf(Repr.Mantissa) - 1);
            },
        }),
        .exponent = std.math.lossyCast(Repr.Normalized.Exponent, exponent),
    };
    return .{ normalized_res.reconstruct(if (self.positive) .positive else .negative), exactness };
}
```
