# std.math.FloatRepr.Normalized

### Fields

    fraction: Fraction

    exponent: Normalized.Exponent

## Values

|          |     |     |
|----------|-----|-----|
| Exponent |     |     |
| Fraction |     |     |

## Functions

`pub fn reconstruct(normalized: Normalized, sign: std.math.Sign) Float`
This currently truncates denormal values, which needs to be fixed before this can be used to produce a rounded value.
